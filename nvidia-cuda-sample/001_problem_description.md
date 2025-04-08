
Summary of the problem:
I'm trying to set up the Nvidia Hymba model in a Docker container using the PyTorch base image. However, I'm encountering an issue with the Nvidia setup script. It requires a /usr/local/cuda directory, which is missing in the PyTorch image.

I've tried creating a Conda environment within the container and running the setup script, but it fails due to the missing CUDA directory.

Many details to explain the problem:

Point 1. I am interested in running on my computer the llm model published by Nvidia
called Hymba.

Point 2. This Hymba model and how to install it is described here:
https://huggingface.co/nvidia/Hymba-1.5B-Base

Point 3. My laptop computer has an nvidia card of type
 Quadro M2000M

Point 4. I am trying to run the image using the https://hub.docker.com/r/pytorch/pytorch 
as my base image.

Point 5. I run the pytoch base image by doing the following
```dockerfile
services:
  # Python development environment with PyTorch
  dev_pytorch:
    image: pytorch/pytorch  # Base image with CUDA and development tools
    container_name: dev_pytorch
    ports:
      - "8888:8888"  # Jupyter notebook port (optional)
    volumes:
      - ./workspace:/workspace  # Mount your current directory as the workspace
    environment:
      - NVIDIA_VISIBLE_DEVICES=all  # Expose all GPUs to the container
    runtime: nvidia  # Enable NVIDIA runtime for GPU support

    # Install additional dependencies (if needed)
    # You can customize this section to install specific libraries
    # command: ["bash", "-c", "apt update && apt install -y python3-pip && pip install --no-cache-dir torch torchvision torchaudio"]
    command: ["sleep", "infinity"]

# You can add additional services here, such as a database or a web server
```

Poing 6. This pytorch image comes with conda installed.
I have setup an empty conda environment in order to allow the Nivida setup.sh file to run.
See for example this snippet:
```
# conda environments:
#
base                 * /opt/conda
nvidia-hymba           /opt/conda/envs/nvidia-hymba
playground             /opt/conda/envs/playground
playground_clone_of_base   /opt/conda/envs/playground_clone_of_base

(base) root@d63bc1497c12:/workspace# conda activate nvidia-hymba
(nvidia-hymba) root@d63bc1497c12:/workspace#
```


Point 7. I have another docker compose file for an NVIDIA container
to test the presence and support of CUDA in docker with runtime accelaration.
This container here:
```
services:
  cuda-sample:
    image: nvcr.io/nvidia/k8s/cuda-sample:nbody
    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]
    runtime: nvidia
    command: nbody -gpu -benchmark
    ```

  Point 8. I have explored the container of point 7 with bin bash and
  have observed that I have similar output when running the command

  ```
  root@8367e2ba5c67:/# nvidia-smi
Tue Nov 26 21:34:31 2024
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 550.127.04             Driver Version: 553.24         CUDA Version: 12.4     |
|-----------------
```
To the pytorch image where i want to run nvidia

Point 9. However there seems to be a very significant difference between the two containers.
The one from NVIDIA to test CUDA locally seems to have some "cuda stuff" in the user local folder.
```demonstration
root@8367e2ba5c67:/# ls -la /usr/local/cuda
cuda/      cuda-11/   cuda-11.7/
root@8367e2ba5c67:/# ls -la /usr/local/cuda
```

However, the pytorch image, where I have tried running the NVIDIA 
setup.sh described in the step 1 of
https://huggingface.co/nvidia/Hymba-1.5B-Base

seems to be lacking any cuda related directory in the /usr/local folder.
```
(nvidia-hymba) root@d63bc1497c12:/workspace# ls -la /usr/local/
total 44
drwxr-xr-x 1 root root 4096 Feb 12  2024 .
drwxr-xr-x 1 root root 4096 Feb 12  2024 ..
drwxr-xr-x 2 root root 4096 Feb 12  2024 bin
drwxr-xr-x 2 root root 4096 Feb 12  2024 etc
drwxr-xr-x 2 root root 4096 Feb 12  2024 games
drwxr-xr-x 2 root root 4096 Feb 12  2024 include
drwxr-xr-x 2 root root 4096 Feb 12  2024 lib
lrwxrwxrwx 1 root root    9 Feb 12  2024 man -> share/man
drwxr-xr-x 2 root root 4096 Feb 12  2024 sbin
drwxr-xr-x 1 root root 4096 Feb 22  2024 share
drwxr-xr-x 2 root root 4096 Feb 12  2024 src
(nvidia-hymba) root@d63bc1497c12:/workspace#
```

Point 10. The point 9 above is a snificant problem.
Why? Because the setup.sh from nvidia
has this snippet of steps
```bash
# Install other packages
pip install --upgrade transformers
pip install tiktoken
pip install sentencepiece
pip install protobuf
pip install ninja einops triton packaging

# Clone and install Mamba
git clone https://github.com/state-spaces/mamba.git
cd mamba
pip install -e .
cd ..

# Clone and install causal-conv1d with specified CUDA version
git clone https://github.com/Dao-AILab/causal-conv1d.git
cd causal-conv1d
export CUDA_HOME=/usr/local/cuda-$cuda_version
TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6;8.9;9.0" python setup.py install
cd ..

# Clone and install attention-gym
git clone https://github.com/pytorch-labs/attention-gym.git
cd attention-gym
pip install .
cd ..

# Install Flash Attention
pip install flash_attn
```

In the snippet above the step that is getting me stuck right now is the one about 
`export CUDA_HOME=/usr/local/cuda-$cuda_version`
as the my user local folder is empty.

Point 11. What I have done so far on this pyoch image was
(a) create a new empty conda environment
(b) activate the conda environment
(c) call the setup.sh of NVIDIA
(d) see the setup fail because of the cuda home problem

NOTE: In my WSL2 ubuntu i can also see that /usr/local/ has cuda 12 folders installed. So I see it as pure problem of the pytorch image lacking some sort of core cuda installation despite having nvidia-smi available.

QUESTION:

1. Do you need any additional information?

2. Do you think there is a chance i can run the model with my GPU it requires CUDA 12.1 or 12.4 the setup.sh ?

3. Do you know why my user local folder might be empty but i also have a docker image where it is not
and what steps i need to undertake to solve the problem?


