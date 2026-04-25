FROM nginx:alpine
COPY build/web /usr/share/nginx/html
EXPOSE 8080
COPY nginx.conf /etc/nginx/conf.d/default.conf
CMD ["nginx", "-g", "daemon off;"]
