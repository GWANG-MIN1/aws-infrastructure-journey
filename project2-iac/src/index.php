<?php
$servername = "my-project-db.cte8mywykw00.ap-northeast-2.rds.amazonaws.com";
$username = "admin";
$password = "*********";
$dbname = "mydb";

// DB 접속 시도 (지금은 실패하는 게 정상)
$conn = new mysqli($servername, $username, $password, $dbname);
?>
<!DOCTYPE html>
<html>
<head>
    <title>Project 2 Docker Test</title>
    <style>
        body { text-align: center; padding: 50px; font-family: Arial, sans-serif; background-color: #f4f4f4; }
        .box { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); display: inline-block; }
        h1 { color: #333; }
        .status { font-weight: bold; color: #e74c3c; } /* 실패 시 빨간색 */
    </style>
</head>
<body>
    <div class="box">
        <h1> Project 2: Docker Mission</h1>
        <p>이 화면이 보이면 <strong>도커 컨테이너</strong>가 정상 작동 중입니다!</p>
        <hr>
        <p>DB 연결 상태: <span class="status">
        <?php
            if ($conn->connect_error) {
                echo "연결 실패 (정상입니다) - " . $conn->connect_error;
            } else {
                echo "연결 성공!";
            }
        ?>
        </span></p>
    </div>
</body>
</html>
