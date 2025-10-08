sudo mkdir -p /etc/apt/keyrings
sudo gpg --no-default-keyring --keyring /etc/apt/trusted.gpg --export \
    | sudo gpg --dearmor -o /etc/apt/keyrings/nvidia.gpg
/etc/apt/sources.list.d/cuda-ubuntu2404-x86_64.list
sudo nano /etc/apt/sources.list.d/cuda-ubuntu2404-x86_64.list
deb [signed-by=/etc/apt/keyrings/nvidia.gpg] https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/ /
sudo rm /etc/apt/sources.list.d/archive_uri-https_developer_download_nvidia_com_compute_cuda_repos_ubuntu2404_x86_64_-noble.list
sudo apt update
