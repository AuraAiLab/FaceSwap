# Setup Guide for Real-Time Deepfake Face-Swapping System

This document provides detailed setup instructions for deploying the real-time deepfake face-swapping system.

## Prerequisites

1. Kubernetes cluster with NVIDIA GPUs (minimum 2 GPUs recommended)
2. NVIDIA GPU Operator installed
3. MetalLB configured for load balancing
4. Persistent storage for models (optional)

## Step-by-Step Setup

### 1. Configure MetalLB Address Pools

Apply the MetalLB configuration to create separate address pools:

```bash
kubectl apply -f metallb-ipaddresspools.yaml
```

This creates two address pools:
- `legacy-pool`: 192.168.20.20-192.168.20.24 (for existing services)
- `new-pool`: 192.168.20.25-192.168.20.29 (for face-swapping pipeline)

### 2. Deploy the Face-Swapping Pipeline

```bash
kubectl apply -f face-swap-dual-gpu-install.yaml
```

This deploys:
- NGINX RTMP server (receives input stream)
- FFmpeg GPU bridge (processes input using GPU 1)
- DeepFaceLive runtime (performs face-swapping using GPU 0)
- Output streamer (delivers RTMP and HLS output)

### 3. Verify Deployment

Check that all pods are running:

```bash
kubectl get pods -o wide
```

Expected output:
```
NAME                   READY   STATUS    RESTARTS   AGE
nginx-rtmp             1/1     Running   0          1m
ffmpeg-gpu-bridge      1/1     Running   0          1m
deepfacelive-runtime   1/1     Running   0          1m
output-streamer        1/1     Running   0          1m
```

Note: `ffmpeg-gpu-bridge` and `output-streamer` may show CrashLoopBackOff until an active stream is provided.

### 4. Verify Service IPs

```bash
kubectl get svc -o wide
```

Expected output:
```
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)
nginx-rtmp-service     LoadBalancer   10.x.x.x        192.168.20.25   1935:xxxxx/TCP
output-stream-service  LoadBalancer   10.x.x.x        192.168.20.26   1940:xxxxx/TCP,8080:xxxxx/TCP
```

## GPU Management

If you need to share GPUs with other services (like Ollama), use the provided script:

```bash
# Install the script
chmod +x ~/scripts/switch-gpu-ownership.sh

# Usage examples
~/scripts/switch-gpu-ownership.sh ffmpeg  # Assign GPU to face-swapping pipeline
~/scripts/switch-gpu-ownership.sh ollama  # Assign GPU to Ollama
~/scripts/switch-gpu-ownership.sh none    # Free up GPUs
```

## Testing the Pipeline

1. Stream to the NGINX RTMP server:
   ```
   ffmpeg -re -i test_video.mp4 -c copy -f flv rtmp://192.168.20.25:1935/live/test
   ```
   
   Or use OBS with these settings:
   - Service: Custom
   - Server: rtmp://192.168.20.25:1935/live
   - Stream Key: test

2. View the output:
   - RTMP: `rtmp://192.168.20.26:1940/live/final`
   - HLS: `http://192.168.20.26:8080/stream.m3u8`

   You can use VLC or other media players to view the streams.

## Troubleshooting

### Common Issues

1. **Pods stuck in Pending state**: Check GPU availability with `nvidia-smi` and ensure no other pods are using the GPUs.

2. **FFmpeg bridge crashes**: Verify that you're streaming to the correct RTMP URL.

3. **No output from DeepFaceLive**: Check the logs with `kubectl logs deepfacelive-runtime` to ensure it's processing the input correctly.

4. **MetalLB IP allocation issues**: Verify the address pools are correctly configured and not overlapping.

### Checking Logs

```bash
kubectl logs nginx-rtmp
kubectl logs ffmpeg-gpu-bridge
kubectl logs deepfacelive-runtime
kubectl logs output-streamer
```

## Advanced Configuration

For advanced configuration options, refer to the individual component documentation:

- [DeepFaceLive GitHub Repository](https://github.com/iperov/DeepFaceLive)
- [NGINX RTMP Module Documentation](https://github.com/arut/nginx-rtmp-module)
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)
