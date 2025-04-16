# Real-Time Deepfake Face-Swapping System

A Kubernetes-based pipeline for real-time face swapping using DeepFaceLive, NGINX RTMP, and FFmpeg with dual GPU support.

## System Architecture

This system creates a complete pipeline for real-time face swapping:

1. **NGINX RTMP Server**: Receives RTMP stream from OBS or other streaming software
2. **FFmpeg GPU Bridge**: Processes the input stream and prepares it for DeepFaceLive (GPU 1)
3. **DeepFaceLive Runtime**: Performs the face-swapping (GPU 0)
4. **Output Streamer**: Takes the processed video and outputs it as RTMP and HLS

## Network Configuration

The system uses MetalLB to expose services with dedicated IP addresses:

- **NGINX RTMP Service**: 192.168.20.25:1935
- **Output Stream Service**: 192.168.20.26 (RTMP: 1940, HLS: 8080)

## Prerequisites

- Kubernetes cluster with at least 2 NVIDIA GPUs
- NVIDIA GPU Operator installed
- MetalLB configured with appropriate address pools
- Persistent storage for models (optional)

## Deployment

### 1. Configure MetalLB Address Pools

```yaml
# metallb-ipaddresspools.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: legacy-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.20.20-192.168.20.24
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: new-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.20.25-192.168.20.29
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: legacy-pool-adv
  namespace: metallb-system
spec:
  ipAddressPools:
  - legacy-pool
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: new-pool-adv
  namespace: metallb-system
spec:
  ipAddressPools:
  - new-pool
```

### 2. Deploy the Face-Swapping Pipeline

```bash
kubectl apply -f face-swap-dual-gpu-install.yaml
```

## Usage

### Streaming Input

Stream to the NGINX RTMP server using OBS or ffmpeg:

```
rtmp://192.168.20.25:1935/live/test
```

### Viewing Output

The processed stream is available at:

- **RTMP**: rtmp://192.168.20.26:1940/live/final
- **HLS**: http://192.168.20.26:8080/stream.m3u8

## GPU Management

A script is provided to manage GPU allocation between the face-swapping pipeline and other services like Ollama:

```bash
# Assign GPU to ffmpeg-gpu-bridge
~/scripts/switch-gpu-ownership.sh ffmpeg

# Assign GPU to Ollama
~/scripts/switch-gpu-ownership.sh ollama

# Remove GPU from both
~/scripts/switch-gpu-ownership.sh none
```

## Troubleshooting

### Common Issues

1. **FFmpeg GPU Bridge in CrashLoopBackOff**: This is normal until a stream is sent to the NGINX RTMP server.
2. **Output Streamer in CrashLoopBackOff**: This pod depends on output from the DeepFaceLive runtime, which requires an active input stream.
3. **GPU Resource Contention**: Use the GPU management script to allocate GPUs appropriately.

### Checking Pod Status

```bash
kubectl get pods -o wide
```

### Viewing Logs

```bash
kubectl logs nginx-rtmp
kubectl logs ffmpeg-gpu-bridge
kubectl logs deepfacelive-runtime
kubectl logs output-streamer
```

## Configuration Files

- `face-swap-dual-gpu-install.yaml`: Main deployment manifest
- `metallb-ipaddresspools.yaml`: MetalLB address pool configuration
- `ollama-deploy-no-gpu.yaml`: Ollama deployment without GPU
- `switch-gpu-ownership.sh`: Script to manage GPU allocation

## License

This project is licensed under the MIT License - see the LICENSE file for details.
