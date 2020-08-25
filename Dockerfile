FROM	python:3.7

ENV	WEB_PORT	8000
ENV    LANG            C.UTF-8

# Install system packages

RUN	set -x \
	&&	apt-get update \
	&&	apt-get install -y --no-install-recommends \
			ffmpeg \
			tree \
			vim \
			zsh \
	&&	rm -rf /var/lib/apt/lists/*

RUN	pip install --upgrade pip

COPY	requirements.txt /requirements.txt

RUN	pip install -r /requirements.txt

# Expose web port to outside; must publish at runtime
EXPOSE	${WEB_PORT}

# Provision my user.

RUN	useradd -m -s /bin/zsh maiko

VOLUME	/home/maiko

USER	maiko
#ENV	BOT_ID		'put_id_here'
#ENV	SLACK_BOT_TOKEN	'put-token-here'

WORKDIR	/home/maiko

CMD ["zsh"]
