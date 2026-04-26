# CrisisSync Cloud Run Deploy - Windows/PowerShell
$ErrorActionPreference = "Stop"

$PROJECT_ID = "crisissync-11156"
$REGION = "asia-south1"           # Mumbai (lowest latency for Badlapur)
$SERVICE_NAME = "crisissync-web"
$IMAGE_NAME = "gcr.io/$PROJECT_ID/$SERVICE_NAME"
$STAGING_DIR = ".deploy_staging"

Write-Host "`n======================================" -ForegroundColor Magenta
Write-Host "  CrisisSync Cloud Run Deployment" -ForegroundColor Magenta
Write-Host "======================================`n" -ForegroundColor Magenta

# Step 1: Flutter build
Write-Host "[1/4] Building Flutter web..." -ForegroundColor Yellow
flutter build web --release --base-href /
if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter build FAILED!" -ForegroundColor Red
    exit 1
}
Write-Host "Flutter build complete.`n" -ForegroundColor Green

# Step 2: Verify build output
if (-not (Test-Path "build\web\index.html")) {
    Write-Host "ERROR: build/web/index.html not found!" -ForegroundColor Red
    exit 1
}
Write-Host "Verified: build/web/index.html exists.`n" -ForegroundColor Green

# Step 3: Prepare staging directory (only what Docker needs)
Write-Host "[2/4] Preparing staging directory..." -ForegroundColor Yellow
if (Test-Path $STAGING_DIR) {
    Remove-Item -Recurse -Force $STAGING_DIR
}
New-Item -ItemType Directory -Path $STAGING_DIR | Out-Null
New-Item -ItemType Directory -Path "$STAGING_DIR\build" | Out-Null

# Copy only the files Cloud Build needs
Copy-Item "Dockerfile" "$STAGING_DIR\"
Copy-Item "nginx.conf" "$STAGING_DIR\"
Copy-Item -Recurse "build\web" "$STAGING_DIR\build\web"

$fileCount = (Get-ChildItem -Recurse -File $STAGING_DIR).Count
Write-Host "Staging ready: $fileCount files copied.`n" -ForegroundColor Green

# Step 4: Docker build & push via Cloud Build (from staging dir)
Write-Host "[3/4] Building & pushing Docker image..." -ForegroundColor Yellow
gcloud builds submit --tag $IMAGE_NAME --project $PROJECT_ID $STAGING_DIR
if ($LASTEXITCODE -ne 0) {
    Write-Host "Cloud Build FAILED!" -ForegroundColor Red
    # Cleanup staging
    Remove-Item -Recurse -Force $STAGING_DIR -ErrorAction SilentlyContinue
    exit 1
}
Write-Host "Docker image pushed.`n" -ForegroundColor Green

# Cleanup staging directory
Remove-Item -Recurse -Force $STAGING_DIR -ErrorAction SilentlyContinue

# Step 5: Deploy to Cloud Run
Write-Host "[4/4] Deploying to Cloud Run ($REGION)..." -ForegroundColor Yellow
gcloud run deploy $SERVICE_NAME `
    --image $IMAGE_NAME `
    --platform managed `
    --region $REGION `
    --allow-unauthenticated `
    --port 8080 `
    --memory 1Gi `
    --cpu 1 `
    --project $PROJECT_ID `
    --quiet
if ($LASTEXITCODE -ne 0) {
    Write-Host "Cloud Run deploy FAILED!" -ForegroundColor Red
    exit 1
}

# Step 6: Get live URL
$URL = gcloud run services describe $SERVICE_NAME --region $REGION --project $PROJECT_ID --format='value(status.url)'
Write-Host "`n======================================" -ForegroundColor Green
Write-Host "  DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host "Live URL : $URL" -ForegroundColor Cyan
Write-Host "Region   : $REGION (Mumbai)" -ForegroundColor Cyan
Write-Host "Service  : $SERVICE_NAME" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Green

# Auto-open in default browser
Start-Process $URL
