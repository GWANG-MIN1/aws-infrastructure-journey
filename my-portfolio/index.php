<!DOCTYPE html>
<html>
<head>
    <title>My Cloud Portfolio</title>
    <style>
        body { font-family: sans-serif; text-align: center; padding-top: 50px; background-color: #f0f8ff; }
        h1 { color: #2c3e50; }
        .box { border: 2px solid #3498db; padding: 20px; display: inline-block; background: white; border-radius: 10px; }
    </style>
</head>
<body>
    <div class="box">
        <h1> 배포 성공!</h1>
        <p>이 페이지는 <strong>AWS 클라우드</strong>에서 실행되고 있습니다.</p>
        <p>현재 시간: <?php echo date("Y-m-d H:i:s"); ?></p>
        <hr>
        <p>Made by Auto <strong>CI/CD</strong></p>
    </div>
</body>
</html>
