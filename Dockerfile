FROM nvidia/cuda:12.2.0-runtime-ubuntu22.04

RUN apt update && apt install -y git python3 python3-pip ffmpeg libgl1-mesa-glx libglib2.0-0 unzip && \
    apt install -y cmake

RUN pip3 install --upgrade pip && \
    pip3 install torch torchvision torchaudio onnxruntime-gpu numpy opencv-python-headless imageio dlib insightface

WORKDIR /app
RUN git clone https://github.com/iperov/DeepFaceLive . && mkdir -p /app/models

CMD ["python3", "main.py"]
