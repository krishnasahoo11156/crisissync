# CrisisSync Cloud Run Deploy - Windows/PowerShell
$ErrorActionPreference = "Stop"

$PROJECT_ID = "crisissync-11156"
$REGION = "asia-south1"           # Mumbai (lowest latency for Badlapur)
$SERVICE_NAME = "crisissync-web"
$IMAGE_NAME = "gcr.io/$PROJECT_ID/$SERVICE_NAME"

Write-Host "`n======================================" -ForegroundColor Magenta
Write-Host "  CrisisSync Cloud Run Deployment" -ForegroundColor Magenta
Write-Host "======================================`n" -ForegroundColor Magenta

# Step 1: Flutter build
Write-Host "[1/3] Building Flutter web..." -ForegroundColor Yellow
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

# Step 3: Docker build & push via Cloud Build
Write-Host "[2/3] Building & pushing Docker image..." -ForegroundColor Yellow
gcloud builds submit --tag $IMAGE_NAME --project $PROJECT_ID
if ($LASTEXITCODE -ne 0) {
    Write-Host "Cloud Build FAILED!" -ForegroundColor Red
    exit 1
}
Write-Host "Docker image pushed.`n" -ForegroundColor Green

# Step 4: Deploy to Cloud Run
Write-Host "[3/3] Deploying to Cloud Run ($REGION)..." -ForegroundColor Yellow
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

# Step 5: Get live URL
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
