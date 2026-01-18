# 1. 베이스 이미지 (PHP 8.1 + Apache)
FROM php:8.1-apache

# 2. DB 접속에 필요한 드라이버 설치
RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli

# 3. 소스 코드 복사
# (프로젝트 루트의 src/index.php를 컨테이너의 웹 폴더로 복사)
COPY src/index.php /var/www/html/

# 4. 80번 포트 개방
EXPOSE 80
