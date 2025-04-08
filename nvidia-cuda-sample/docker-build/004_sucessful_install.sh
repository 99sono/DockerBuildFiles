Building wheels for collected packages: attn_gym
  Building wheel for attn_gym (pyproject.toml) ... done
  Created wheel for attn_gym: filename=attn_gym-0.0.3.dev4+g36f8bd5-py3-none-any.whl size=15165 sha256=f202c12add81b328331a82a74af0647918628fa144d7f2c4562d46ac236f2c09
  Stored in directory: /root/.cache/pip/wheels/6c/95/68/a90037338408b8f8c1410b480269cf43a5daa559d4b679d5ca
Successfully built attn_gym
Installing collected packages: attn_gym
  Attempting uninstall: attn_gym
    Found existing installation: attn_gym 0.0.3.dev4+g36f8bd5
    Uninstalling attn_gym-0.0.3.dev4+g36f8bd5:
      Successfully uninstalled attn_gym-0.0.3.dev4+g36f8bd5
Successfully installed attn_gym-0.0.3.dev4+g36f8bd5
WARNING: Running pip as the 'root' user can result in broken permissions and conflicting behaviour with the system package manager, possibly rendering your system unusable.It is recommended to use a virtual environment instead: https://pip.pypa.io/warnings/venv. Use the --root-user-action option if you know what you are doing and want to suppress this warning.
Collecting flash_attn
  Using cached flash_attn-2.7.0.post2.tar.gz (2.7 MB)
  Preparing metadata (setup.py) ... done
Requirement already satisfied: torch in /opt/conda/envs/nvidia-hymba/lib/python3.9/site-packages (from flash_attn) (2.5.0)
Requirement already satisfied: einops in /opt/conda/envs/nvidia-hymba/lib/python3.9/site-packages (from flash_attn) (0.8.0)
Requirement already satisfied: filelock in /opt/conda/envs/nvidia-hymba/lib/python3.9/site-packages (from torch->flash_attn) (3.13.1)
Requirement already satisfied: typing-extensions>=4.8.0 in /opt/conda/envs/nvidia-hymba/lib/python3.9/site-packages (from torch->flash_attn) (4.11.0)
Requirement already satisfied: networkx in /opt/conda/envs/nvidia-hymba/lib/python3.9/site-packages (from torch->flash_attn) (3.2.1)
Requirement already satisfied: jinja2 in /opt/conda/envs/nvidia-hymba/lib/python3.9/site-packages (from torch->flash_attn) (3.1.4)
Requirement already satisfied: fsspec in /opt/conda/envs/nvidia-hymba/lib/python3.9/site-packages (from torch->flash_attn) (2024.10.0)
Requirement already satisfied: sympy==1.13.1 in /opt/conda/envs/nvidia-hymba/lib/python3.9/site-packages (from torch->flash_attn) (1.13.1)
Requirement already satisfied: mpmath<1.4,>=1.1.0 in /opt/conda/envs/nvidia-hymba/lib/python3.9/site-packages (from sympy==1.13.1->torch->flash_attn) (1.3.0)
Requirement already satisfied: MarkupSafe>=2.0 in /opt/conda/envs/nvidia-hymba/lib/python3.9/site-packages (from jinja2->torch->flash_attn) (2.1.3)
Building wheels for collected packages: flash_attn
  Building wheel for flash_attn (setup.py) ... done
  Created wheel for flash_attn: filename=flash_attn-2.7.0.post2-cp39-cp39-linux_x86_64.whl size=183288790 sha256=7ca0eef94069845ef6f66160ba831526c74f9b6119834b6b9885b14e4dd3e6ab
  Stored in directory: /root/.cache/pip/wheels/7c/d2/fc/00adef0a32dae2d3b23eb6773900c99b8e1d9e8778ad8fa8a5
Successfully built flash_attn
Installing collected packages: flash_attn
Successfully installed flash_attn-2.7.0.post2
WARNING: Running pip as the 'root' user can result in broken permissions and conflicting behaviour with the system package manager, possibly rendering your system unusable.It is recommended to use a virtual environment instead: https://pip.pypa.io/warnings/venv. Use the --root-user-action option if you know what you are doing and want to suppress this warning.
Installation completed with CUDA 12.4.