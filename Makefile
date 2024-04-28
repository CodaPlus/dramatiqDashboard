build: 
	docker build --no-cache -t dramatiq_dash .   

stop:
	docker stop drmatiq_Dashboard

delete:
	docker rm -f drmatiq_Dashboard

run: 
	docker rm -f drmatiq_Dashboard
	docker build -t dramatiq_dash .   
	docker run -p 3660:8400 --hostname 0.0.0.0 --restart unless-stopped --name drmatiq_Dashboard -d dramatiq_dash