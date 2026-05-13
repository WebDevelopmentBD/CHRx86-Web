<?php if(file_exists('/home/data/index.php')){
	include('/home/data/index.php');
}else if(file_exists('/home/data/index.html')){
	include('/home/data/index.html');
}else{
	phpinfo();
}?>