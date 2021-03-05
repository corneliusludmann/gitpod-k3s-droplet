FROM gitpod/workspace-base:latest

RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list && \
    sudo install-packages shellcheck kubectl

RUN curl -OsSL https://github.com/digitalocean/doctl/releases/download/v1.57.0/doctl-1.57.0-linux-amd64.tar.gz && \
    tar -xf doctl-1.57.0-linux-amd64.tar.gz && \
    sudo mv doctl /usr/local/bin/ && \
    rm doctl-1.57.0-linux-amd64.tar.gz && \
    echo 'source  <(doctl completion bash)' > /home/gitpod/.bashrc.d/doctl-bash-completion.sh
