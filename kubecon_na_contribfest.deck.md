---
theme: kubecon_na
seaborn_theme: kubecon_na
title: "GPU Virtualization: First Setup and Understanding the Device Plugin / DRA"
logo: assets/brand/dynamia-logo.svg
logo_dark: assets/brand/dynamia-logo-white.png
watermark: assets/brand/cncf-logo.png
footer: "KubeCon + CloudNativeCon North America 2026 · ContribFest"
transition: fade
paginate: true
size: 16:9
style: |
  section.lab h1 { font-size: 3em; }
  img[src$=".svg"] { max-height: 360px; }
  img[src*="containerdays-lab-architecture"] { max-height: 290px; }
  img[src*="containerdays-webui-overview"] { max-height: 240px; }
  .layout-title .side-image { width: 170px; bottom: 40%; }
  .layout-title .side-image img { width: 170px; max-width: 170px; max-height: none; }

---

<!--
80 min ContribFest (KubeCon + CloudNativeCon North America 2026, Tue Nov 10, 4:40 to 6:00 pm MST, Salt Palace Level 2, 255 D). Based on gpu_workshop.deck.md.
Lab commands and outputs on these slides are from a run on 2026-10-20 (kind 0.33, kubectl 1.37, helm 4.3, HAMi chart 2.10.0, hami-mock-monitor 86adb51); Labs 2 and 3 re-verified 2026-10-23.
-->
@variant dark
@kicker KubeCon + CloudNativeCon North America 2026 · ContribFest

# GPU Virtualization: First Setup and Understanding the Device Plugin / DRA

@speaker name="Reza Jelveh" role="Solution Architect, Dynamia AI  -  Makers of HAMi" github=github.com/fishman linkedin=linkedin.com/in/rezajelveh
@speaker name="Mengxuan Li" role="CTO, Dynamia AI  -  HAMi maintainer"

---

## The 80 minutes

@layout timeline-horizontal
@subtitle Tuesday, November 10, 4:40 to 6:00 pm · Salt Palace 255 D

::: grid {cols=5}
::: card {label="4:40"}
### Lab 1
Install HAMi
:::
::: card {label="4:55"}
### Lab 2
Share a GPU
:::
::: card {label="5:10"}
### Lab 3
binpack vs spread
:::
::: card {focus, label="5:25"}
### Lab 4
DRA
:::
::: card {label="5:45"}
### Contribute
First PR
:::
:::

<!--
Lab guide: github.com/Project-HAMi/hami-workshop → Labs
-->

<!--
Ask who has the before-session pull already done. Helpers raise hands so people know who to ask.
-->

---

## Before the session

@subtitle Everything runs on your laptop. The GPUs are fake.

```bash
git clone https://github.com/Project-HAMi/hami-workshop
cd hami-workshop/examples/containerdays-singapore
git clone https://github.com/fishman/hami-mock-monitor
docker pull kindest/node:v1.37.0 busybox:1.36 ghcr.io/llm-d/llm-d-inference-sim:v0.12.0
```

- Needs Docker (or OrbStack / Colima), 4 CPU and 8 GB free, plus `kind`, `kubectl`, `helm`, `jq`, `git`
- Go 1.27+ only to build HAMi or contribute code. A GitHub account for Lab 4
- Conference Wi-Fi is slow. Pull images at home

---

# Why share GPUs

---

## One GPU per task is the default

@subtitle What it costs

Kubernetes allocates GPUs atomically: one whole device, one task.

- A 1 GB task blocks an 80 GB device
- Most GPUs sit idle most of the time
- No advanced scheduling yet: no binpack, no spread, no topology

![Device Plugin vs DRA](assets/hami/device-plugin-vs-dra.png)

---

## What is HAMi

@subtitle One GPU, many tasks

<!--
HAMi is a CNCF Incubating project for heterogeneous GPU virtualization in Kubernetes, supporting 10+ GPU/NPU vendors. It slices GPUs and shares them across workloads, without rewriting your stack.
-->
![After HAMi](assets/hami_intro/after-hami.png)

---

## HAMi Capabilities

@subtitle Six things HAMi brings to GPU scheduling

<!--
Six capabilities. The key ones for this workshop: hard isolation, advanced scheduling, and unified monitoring. Heterogeneous management is the differentiator, not just NVIDIA.
-->

::: grid {cols=2}
::: card
### {icon:layers cls=accent-primary} Heterogeneous Management

Manage GPU, NPU, MLU, and other accelerators in one workflow.
:::
::: card
### {icon:shield-check cls=accent-primary} Hard Isolation

Slice memory and compute with hard isolation at runtime.
:::
::: card
### {icon:git-branch cls=accent-contrast} Advanced Scheduling

Binpack, spread, and topology-aware placement policies.
:::
::: card
### {icon:box cls=accent-primary} Kubernetes Native

Kubernetes-native APIs, DRA, and CDI support.
:::
::: card
### {icon:gauge cls=accent-primary} Resource Isolation & QoS

Memory and core quotas for fair, stable sharing.
:::
::: card
### {icon:chart-bar cls=accent-contrast} Unified Monitoring

Consistent metrics and visibility across vendors.
:::
:::

---

@layout two-col

## Asking for a slice

@subtitle One API across vendors, no code changes

- **NVIDIA, Ascend, Cambricon, Hygon, Iluvatar** and more
- **Fine-grained:** memory as small as 1 MB, compute as small as 1% of a card
- **Transparent to tasks:** no code changes required
- **Hard resource isolation** inside containers

@col

```yaml
# NVIDIA: 15 GB and 30% of one card
resources:
  limits:
    nvidia.com/gpu: 1
    nvidia.com/gpumem: 15000
    nvidia.com/gpucores: 30
```

```yaml
# Ascend 910C: 8GB + 20% compute
resources:
  limits:
    huawei.com/Ascend910C: "1"
    huawei.com/Ascend910C-core: "20"
    huawei.com/Ascend910C-memory: "8192"
```

---

## Where HAMi sits in the GPU stack

```pdg
graph layout=column align=stretch gap=8 theme=hami
default group layout=row gap=10 .tier
group l5 "Kubernetes scheduling" {
  ks "kube-scheduler"
  hs "HAMi scheduler" .hami
  p "Pod"
}
group l4 "Container runtime" {
  c "containerd"
  t "NVIDIA Container Toolkit"
  hc "HAMi-Core" .hami
}
group l3 "User-space libraries" {
  cu "CUDA"
  nv "NVML"
  smi "nvidia-smi"
}
group l2 "Kernel driver" {
  ko "nvidia.ko"
  uvm "nvidia-uvm.ko"
}
group l1 "Hardware" {
  g "NVIDIA GPU"
  pc "PCIe"
  nl "NVLink"
}
legend .hami "HAMi component"
css {
  group.tier { fill: #ffffff; stroke: var(--border); title-fill: none; padding: 8px 12px; }
  node { font-weight: normal; padding: 5px 12px; }
  node.hami { fill: var(--green); stroke: var(--green); color: #ffffff; font-weight: 600; }
}
```

---

## A Pod's path to the GPU

```pdg
graph layout=row theme=hami gap=40 steps=auto
group panels layout=row align=stretch gap=40 .bare {
group cp "Control plane" sub="decides where the Pod runs" layout=column gap=30 {
  pod "Pod" sub="nvidia.com/gpumem: 3000"
  webhook "MutatingWebhook" sub="sets schedulerName" .blue
  sched "HAMi scheduler" sub="picks a node and a card" .blue
}
group node "GPU node" sub="sets up the container, enforces limits" layout=column gap=30 .green {
  kubelet "kubelet" sub="starts the Pod"
  plugin "HAMi device plugin" sub="mounts libvgpu.so" .green
  core "HAMi-Core" sub="checks memory and kernel calls" .green
}
}
gpu "GPU" border=glow
pod -> webhook flow=forward
webhook -> sched flow=forward
sched -> kubelet "bind" flow=forward
kubelet -> plugin "Allocate()" flow=forward
plugin -> core flow=forward
core -> gpu flow=forward
css { group.bare { fill: none; stroke: none; padding: 0; } }
```

<!--
Code: cmd/scheduler, cmd/device-plugin, cmd/vGPUmonitor, pkg/device/<vendor>
-->

---

## How the HAMi components work together

```pdg
graph layout=row theme=hami gap=56
group cp "Control plane" layout=column gap=22 {
  api "Kubernetes API" sub="Pods · node annotations"
  hs "hami-scheduler Pod" sub="webhook + extender · :9395" .blue
}
group node "Each GPU node" layout=column gap=22 .green {
  dp "hami-device-plugin" sub="DaemonSet · registers cards" .green
  core "HAMi-core" sub="libvgpu.so in the container" .green
  mon "vGPUmonitor" sub="usage · :9394" .green
}
group obs "Observability" layout=column gap=22 {
  prom "Prometheus" sub="scrapes :9395 and :9394"
  ui "HAMi-WebUI" sub="read-only dashboards" .blue
}
dp -> api "node-nvidia-register"
api <-> hs "annotations"
dp -> core "mounts"
core -> mon "shared region"
hs -> prom "allocated"
mon -> prom "used"
prom -> ui
```

<!--
The device plugin writes card inventory into a node annotation. The scheduler reads it, picks a card and writes the allocation into Pod annotations. On the node the device plugin mounts HAMi-core, which records usage that vGPUmonitor exports. Prometheus scrapes both; the WebUI reads Prometheus and the API.
-->

---

## Why `nvidia-smi` can fail when `lsmod` looks fine

```pdg
graph layout=column align=stretch gap=8 theme=hami
group user "User space" layout=row gap=24 .space {
  nvml "libnvidia-ml.so" sub="NVML" align-x=nvidia .blue
  libcuda "libcuda.so" sub="CUDA driver API" align-x=uvm .blue
}
group kernel "Kernel space" layout=row gap=60 .kspace {
  nvidia "nvidia" sub="core GPU driver" .green
  uvm "nvidia_uvm" sub="unified memory" .green
}
group hw "Hardware" layout=row .space {
  gpu "NVIDIA GPU"
}
nvml -> nvidia
libcuda -> uvm "ioctl"
uvm -> nvidia "depends on"
nvidia -> gpu
bracket nvml, gpu "nvidia-smi needs\nthe whole path"
bracket nvidia, uvm "lsmod checks\nonly this layer"
css {
  group.space, group.kspace { label-position: left; title-fill: none; stroke: none; }
  group.space { fill: #eff6ff; color: var(--blue); }
  group.kspace { fill: #f0fdf4; color: var(--green); }
  node.blue, node.green { accent-bar: none; }
  node.blue { color: var(--blue); }
  node.green { color: var(--green); }
}
```

HAMi-Core intercepts at the CUDA and NVML layer, above the kernel driver.

---

## Lab setup: real scheduler, fake GPUs

```pdg
graph layout=row theme=hami gap=48
you "You" sub="laptop · kubectl"
group kind "kind cluster hami-lab" layout=column gap=36 {
  group top layout=row gap=40 .bare {
    sched "HAMi scheduler" sub=":9395 · real" .green
    node "hami-lab node" sub="2 × A100-40GB fake"
    plugin "mock-device-plugin" sub="gpumem · gpucores"
  }
  group bottom layout=row gap=40 .bare {
    pods "Pods" sub="share · pack · sim" .blue
    monitor "hami-mock-monitor" sub=":9394 · usage"
  }
}
plugin -> node
node -> sched "capacity"
you -> sched "kubectl apply"
sched -> pods "fit + bind" flow=forward
pods -> monitor "usage"
monitor -> you "metrics"
css { group.bare { fill: none; stroke: none; padding: 0; } }
```

::: grid {cols=2}
::: card {tag=cyan}
### mock-device-plugin
Turns a node annotation into `nvidia.com/gpumem` and `nvidia.com/gpucores` capacity. The real device plugin writes that annotation from NVML.
:::
::: card {tag=green}
### hami-mock-monitor
Produces HAMi's usage metrics (normally from vGPUmonitor and HAMi-core) from a load source instead of a GPU.
:::
:::

<!--
What you do not get without a GPU: memory and compute isolation inside the container. That part is HAMi-core, shown live on a real card in the wrap-up.
-->

---

@variant dark
<!--
12:30. Target: 10 minutes. Helpers check everyone gets gpumem=81920.
-->

# Lab 1: Install HAMi

---

## Lab 1: one command

```bash
./setup.sh
```

The script:

1. Creates a kind cluster `hami-lab` and labels the node `gpu=on`
2. Installs HAMi 2.10.0 with the real device plugin off and the mock plugin on
3. Fakes two A100-40GB cards. Two pieces:
    - the count resource `nvidia.com/gpu=20`: the mock plugin's health gate, 2 cards x 10 splits
    - the node annotation `hami.io/node-nvidia-register` from `fake-gpus.json`, what the real device plugin writes after it reads NVML
4. Builds and installs hami-mock-monitor with `completeBinds=true`

Expected at the end:

```json
{ "nvidia.com/gpu": "20", "nvidia.com/gpucores": "200",
  "nvidia.com/gpumem": "81920", "nvidia.com/gpumem-percentage": "200" }
```

---

## Lab 1: look around

```bash
kubectl -n kube-system get pods | grep hami
kubectl -n kube-system get cm hami-scheduler-device -o yaml | less
kubectl get node hami-lab-control-plane \
  -o jsonpath='{.metadata.annotations.hami\.io/node-nvidia-register}' | jq
```

```text
[{"id":"GPU-mock-0","index":0,"count":10,"devmem":40960,"devcore":100,
  "type":"NVIDIA-A100-SXM4-40GB","health":true,"numa":0,"mode":"hami-core"}, ...]
```

- `count`: how many Pods may share the card. `devmem` in MB, `devcore` in percent
- The card list lives on the node, written by the device plugin. The scheduler reads it at `Filter`

<!--
Questions from the guide: Where does the scheduler get the card list from? What would change if health was false?
-->

---

@variant dark
<!--
12:40. Target: 12 minutes. Ask: why is too-big pending when 3 x 15000 < 81920?
-->

# Lab 2: Share a GPU

---

## Lab 2: three Pods, two cards

```bash
kubectl apply -f share.yaml -f too-big.yaml
kubectl get pods -o wide
```

`share-1..3` each ask for 15000 MB and 30% of a card, and run. `too-big` asks for 45000 MB, more than any 40960 MB card, and stays `Pending`:

```bash
kubectl get events --field-selector involvedObject.name=too-big | tail -2
# 0/1 nodes are available: 1 2/2 CardInsufficientMemory.
```

45000 MB fits the node total, but no single 40960 MB card.

---

## Lab 2: read what HAMi decided

```bash
for p in share-1 share-2 share-3; do
  echo -n "$p "; kubectl get pod $p -o jsonpath='{.metadata.annotations.hami\.io/vgpu-devices-allocated}{"\n"}'
done
# share-1 GPU-mock-1,NVIDIA,15000,30:;
# share-2 GPU-mock-0,NVIDIA,15000,30:;
# share-3 GPU-mock-1,NVIDIA,15000,30:;
```

The format is `uuid,type,memory_mb,cores:` per device, `;` per container. The device plugin reads it in `Allocate`.

---

## The interception chain

@subtitle Four steps, one node

1. The admission **webhook** rewrites `schedulerName` to `hami-scheduler`
2. The scheduler **extender** at `Filter` reads the node annotation `hami.io/node-nvidia-register` (the card list from Lab 1), checks memory and core headroom per card, and picks a physical card UUID
3. At `Bind` it writes `hami.io/vgpu-devices-allocated` onto the Pod, sets `hami.io/bind-phase=allocating` and takes the node lock `hami.io/mutex.lock`
4. The device plugin's `Allocate` mounts `/dev/nvidia*` and the vGPU files, reading the target from the Pod annotation, then marks `success` and releases the lock

::: notes{ tag="green" }
The mock plugin skips step 4's completion, which is why hami-mock-monitor's `completeBinds` exists. Without it the next Pod waits up to 5 minutes for the lock.
:::

On a real node, step 4 also injects `libvgpu.so` via `ld.so.preload`, and HAMi-core enforces the memory and core limits from that moment on.

---

@variant dark
<!--
12:50. Target: 12 minutes, now with four concept slides up front (scheduling policies, GPU binpack, GPU spread, topology): keep them to ~3 minutes together, or cut topology to one sentence. The whole workshop already runs over 45 min (see practice/workshop.md cut list). One node, so the node axis has a single candidate. The card axis is fully observable on the two fake A100s.
-->

# Lab 3: Scheduler policies

---

@layout image-right

## Scheduling policies

@subtitle Binpack & spread, on nodes and on GPUs

<!--
Two axes, four patterns. Node binpack saves money, node spread saves uptime. GPU binpack saves whole GPUs for training, GPU spread saves tail latency. Pick by workload: training and small fleets want binpack, inference with SLOs wants spread. (From the KubeCon Japan SNOW talk and OSS Summit Korea.)
-->

![Binpack vs Spread scheduling](assets/hami_intro/scheduling_strategies.png)

- **Node binpack** frees whole machines: reduces cost, helps cluster autoscaler
- **Node spread** isolates faults: HA across zones, blast radius control
- **GPU binpack** prevents fragmentation: frees entire GPUs for training
- **GPU spread** protects tail latency: reduces HBM and NVLink contention

---

@layout two-col

## GPU binpack

@subtitle Fill one card, run many workloads

<!--
GPU binpack puts several workloads on the same card, each with its own slice of memory and compute. It matters most when cards are scarce: small workloads stop blocking whole cards, so the job that cannot share still finds an empty one.
-->

- Several workloads share one card, each with its own slice of memory and compute
- Prevents fragmentation: scattered small workloads no longer block whole cards
- Frees whole cards for the job that cannot share
- Best for: fleets of small workloads, batch jobs, dev and test

@col

![GPU Binpack](drawings/gpu_binpack.drawio.png)

---

@layout two-col

## GPU spread

@subtitle One workload per card, no shared bottlenecks

<!--
GPU spread puts each workload on its own card. No tenant shares compute or memory bandwidth with another, so a thrashing neighbour does not slow the others. Use it for latency-sensitive serving. Next: try both on the two fake A100s.
-->

- One workload per card: compute and memory bandwidth are never shared
- Isolates noisy neighbours: a thrasher on one card does not slow the others
- Protects tail latency: no cross-tenant contention
- Best for: latency-sensitive serving with strict SLOs

@col

![GPU Spread](drawings/gpu_spread.drawio.png)

---

@layout image-right

## Scheduling policies

@subtitle Topology-aware

<!--
NVLink vs PCIe is a 7-14x bandwidth gap. HAMi schedules multi-GPU workloads to NVLink-connected pairs and avoids PCIe bridge pairs. Ascend uses HCCS, other vendors have their own high-speed interconnects: same topology logic applies. This matters for tensor parallelism and large-model training. (From the KubeCon Japan SNOW talk.)
-->

![NUMA topology-aware scheduling](assets/hami_intro/topology_numa.png)

- **NVLink 3 (A100):** 600 GB/s, 12 links
- **NVLink 4 (H100/H200):** 900 GB/s bidirectional across 18 links
- **NVLink 5 (B200/B300):** 1.8 TB/s, 14x PCIe 5.0
- **NVLink 6 (Rubin):** ~3.6 TB/s target
- **PCIe 5.0 x16:** 128 GB/s. **PCIe 6.0:** 242 GB/s
- **HAMi topology policy:** prefers NVLink (NVIDIA), HCCS (Ascend), and other high-speed interconnects, avoids PCIe bridge pairs

---

## Placement happens on two axes

| Axis | Annotation | binpack | spread |
| --- | --- | --- | --- |
| Which node | `hami.io/node-scheduler-policy` | fewer nodes | across nodes |
| Which card on that node | `hami.io/gpu-scheduler-policy` | same card | across cards |

- Both axes score cards by utilization ratios: binpack prefers the fuller card (consolidation), spread prefers the emptier one (dispersion)
- This lab has one node, so the node axis has a single candidate
- The card axis is fully observable on the two fake A100s

---

## Lab 3: binpack

```bash
kubectl delete -f share.yaml -f too-big.yaml
kubectl apply -f binpack.yaml
for p in pack-1 pack-2; do
  echo -n "$p "; kubectl get pod $p -o jsonpath='{.metadata.annotations.hami\.io/vgpu-devices-allocated}{"\n"}'
done
```

Both Pods report the same `GPU-mock-X`: two workloads sharing one card. Frees whole cards for big jobs.

---

## Lab 3: spread

```bash
kubectl delete -f binpack.yaml
kubectl apply -f spread.yaml
for p in spread-1 spread-2; do
  echo -n "$p "; kubectl get pod $p -o jsonpath='{.metadata.annotations.hami\.io/vgpu-devices-allocated}{"\n"}'
done
```

One Pod per card. Same cluster, same requests, different policy, different placement.

```yaml
metadata:
  annotations:
    hami.io/gpu-scheduler-policy: spread   # or binpack, per Pod
```

---

## Where topology information comes from

@subtitle Every vendor: the node's device plugin reads it, an annotation carries it, the scheduler scores it

```pdg
graph layout=row theme=hami gap=56
group src "On the node" layout=column gap=14 {
  nv "NVIDIA · NVML" sub="NVLink and PCIe P2P links"
  amd "AMD · KFD topology" sub="XGMI peers, NUMA node"
  mx "MetaX · vendor plugin" sub="MetaXLink and PCIe switch"
  kl "Kunlunxin, AWS Neuron" sub="fixed board layout by index"
}
dp "Device plugin" sub="per vendor, DaemonSet" .green
anno "Node annotations" sub="register: numa, links\nscores: pair scores" border=glow
hs "hami-scheduler" sub="Filter + Score per vendor" .blue
nv -> dp
amd -> dp
mx -> dp
kl -> dp
dp -> anno "patches" flow=forward
anno -> hs "reads" flow=forward
```

<!--
The scheduler never talks to the hardware. Whatever the device plugin can see on the node, it writes into node annotations; the scheduler's per-vendor code in pkg/device/<vendor> turns that into a card choice. Kubelet's Topology Manager is the second, node-local source (CPU/NUMA alignment); for NVIDIA the plugin can ask the scheduler to refit when they disagree.
-->

---

## Topology, vendor by vendor

- **NVIDIA:** `ENABLE_TOPOLOGY_SCORE=true` scores every card pair from NVML into `hami.io/node-nvidia-score`. Policy `topology-aware`: one card gets the weakest-linked card, N cards get the best-linked set
- **AMD:** `xgmiPeers` and `numa` per GPU in `hami.io/node-amd-register`. Pod annotations `amd.com/numa-bind`, `amd.com/link-bind`, or policy `topology-aware`
- **MetaX:** the vendor plugin writes `metax-tech.com/gpu.topology.scores` and `.losses`. MetaXLink first, then PCIe switch
- **Kunlunxin, AWS Neuron:** no link data; the layout is fixed, so the scheduler reads it from card index (NUMA halves of 8, Neuron rings)

```yaml
metadata:
  annotations:
    hami.io/gpu-scheduler-policy: topology-aware
```

<!--
Every register annotation also carries a numa field per card. Kunlunxin: 1, 2, 4 or 8 cards, 1–4 must not cross NUMA, minimise fragmentation. Asymmetric NVIDIA P2P data scores 0 and raises an AsymmetricGPUP2PLink node event. AMD topology-aware needs a HAMi release newer than v2.10.0. Code: pkg/device/nvidia/calculate_score.go, pkg/device/amd/device.go (bestLinkedCombination), pkg/device/metax/sdevice.go, pkg/device/kunlun/topo.go, pkg/device/awsneuron/device.go (graphSelect).
-->

---

@variant dark
<!--
13:00. Target: 10 minutes. Read-along section: no live installs, 10 minutes does not fit them and one fake node does not need them.
-->

# Lab 4: Beyond the default scheduler

---

## HAMi is two things

@subtitle One isolation layer, several scheduling brains

```pdg
graph layout=column theme=hami gap=22
group inputs layout=row gap=90 .bare {
  pod "GPU Pod" sub="fractional request"
  adm "Admission" sub="mutating webhook"
  dra "HAMi-DRA" sub="gpu → claim"
}
group brains "Scheduling brains" layout=row gap=60 {
  ext "HAMi extender" sub="gpumem · gpucores" .blue
  vol "Volcano" sub="vgpu-* · gang · queue" .blue
  kai "KAI Scheduler" sub="gpu-fraction · topo" .blue
  ks "kube-scheduler" sub="DRA driver · 1.34+"
}
core "HAMi-core" sub="libvgpu.so · hard isolation" .green border=glow
pod -> adm
adm -> ext "default"
adm -> vol "volcano"
adm -> kai "KAI"
adm -> dra "DRA"
dra -> ks
ext -> core
vol -> core
kai -> core
ks -> core "via isolator"
css { group.bare { fill: none; stroke: none; padding: 0; } }
```

<!--
A capacity model: the extended resources plus the scheduler extender you just used. HAMi-core: the isolation library. Other schedulers can replace the placement brain and keep the isolation layer.
-->

---

## Three ways to use HAMi

::: grid {cols=3}
::: card {tag=cyan}
### Standard HAMi
HAMi scheduler extender + HAMi device plugin.
`nvidia.com/gpu`, `gpumem`, `gpucores`
:::
::: card {tag=green}
### Volcano vGPU
Volcano `deviceshare` + volcano-vgpu-device-plugin.
`volcano.sh/vgpu-number`, `vgpu-memory`, `vgpu-cores`
:::
::: card {tag=yellow}
### KAI Scheduler
KAI GPU sharing + kai-resource-isolator.
`gpu-memory` or `gpu-fraction` annotation
:::
:::

All three use **HAMi-core** in the container for isolation. One rule: one device-plugin path per GPU node.

---

## KAI Scheduler: composes with HAMi

NVIDIA's scheduler for AI workloads (CNCF Sandbox): gang scheduling, hierarchical fair queues, fractional GPU, topology-aware placement.

```bash
helm install kai-scheduler oci://ghcr.io/nvidia/kai-scheduler --version v0.17.0 \
  --set global.gpuSharing=true --set binder.plugins.hamicore.enabled=true \
  -n kai-scheduler --create-namespace
```

- Since v0.16.4 the kai-resource-isolator DaemonSet plus a mutating webhook deliver the same `libvgpu.so` into Pods
- `CUDA_DEVICE_MEMORY_LIMIT` injected from `gpu-fraction` or `gpu-memory` annotations
- KAI makes the placement decisions, HAMi-core makes the memory cap hard

---

## Volcano: gang jobs on shared GPUs

```yaml
kind: Job                    # batch.volcano.sh/v1alpha1
spec:
  schedulerName: volcano
  minAvailable: 2            # both workers or none
  queue: vgpu-queue
  tasks:
  - replicas: 2
    template:
      spec:
        containers:
        - resources:
            limits:
              volcano.sh/vgpu-number: 1
              volcano.sh/vgpu-memory: 2000
              volcano.sh/vgpu-cores: 30
```

- Volcano `deviceshare` plugin plus the volcano-vgpu-device-plugin, not the standard HAMi chart
- Queue `capability` caps vGPU memory per team

<!--
Never run the standard HAMi device plugin and a Volcano vGPU plugin on the same node.
-->

---

@variant dark
<!--
5:25. Target: 20 minutes. Read-along plus the claim YAML. Live only on the presenter's 1.34+ cluster.
-->

# Lab 4: DRA

@subtitle Same Pod spec, a different resource model

---

## Device plugin vs DRA

```pdg
graph layout=row theme=hami gap=60
group dp "Device plugin" sub="classic HAMi" layout=column gap=24 {
  dpp "HAMi device plugin" sub="reports each card 10 times" .blue
  ann "Node annotation" sub="hami.io/node-nvidia-register"
  ext "HAMi scheduler extender" sub="reads the annotation, picks a card" .blue
}
group dra "DRA" sub="HAMi-DRA, Kubernetes 1.34+" layout=column gap=24 .green {
  drv "DRA driver" sub="kubelet plugin" .green
  rs "ResourceSlice" sub="typed attributes and capacity"
  ks "kube-scheduler" sub="DRA plugin, no extender" .green
}
dpp -> ann "writes"
ann -> ext "reads"
drv -> rs "publishes"
rs -> ks "reads"
```

<!--
Device plugin: the scheduler sees a count (nvidia.com/gpu: 10), card details travel in an annotation. DRA: the scheduler reads model, memory and UUID from API objects.
-->

---

## The four DRA objects

::: grid {cols=2}
::: card {tag=cyan}
### ResourceSlice
Published by the DRA driver. Lists each device with its attributes and capacity.
:::
::: card {tag=green}
### DeviceClass
A named set of devices, selected with CEL. HAMi: `hami-core-gpu.project-hami.io`
:::
::: card {tag=yellow}
### ResourceClaim
A Pod's request for devices, like a PersistentVolumeClaim.
:::
::: card {tag=red}
### ResourceClaimTemplate
Kubernetes creates one ResourceClaim per Pod from it.
:::
:::

---

## Consumable capacity: one card, many claims

```yaml
capacity:
  cores:
    value: "100"
    requestPolicy: { validRange: { min: "0", max: "100", step: "1" } }
  memory:
    value: 15Gi
    requestPolicy: { validRange: { min: 1Mi, max: 15Gi, step: 1Mi } }
```

- A Tesla T4 published as one device with two capacities, plus `allowMultipleAllocations: true`
- The scheduler does the accounting and enforces min, max and step. Extended resources accept any number
- Feature gate `DRAConsumableCapacity`: alpha in 1.34, on by default since 1.36

---

## A claim for 4Gi and 30 cores

```yaml
apiVersion: resource.k8s.io/v1
kind: ResourceClaim
metadata: { name: single-gpu-0, namespace: test-dra }
spec:
  devices:
    requests:
    - name: single-gpu
      exactly:
        deviceClassName: hami-core-gpu.project-hami.io
        capacity:
          requests: { cores: 30, memory: "4Gi" }
```

```text
| N/A   59C    P8   16W /  70W |   0MiB /   4096MiB |   0%   Default |
```

`nvidia-smi` in the Pod reports 4096 MiB: HAMi-Core enforces the claim. A second Pod's claim lands on the same card, same UUID, its own `shareID`.

---

## HAMi-DRA: keep the HAMi Pod spec

```pdg
graph layout=row theme=hami gap=36 steps=auto
pod "Pod" sub="nvidia.com/gpu, gpumem, gpucores"
wh "HAMi-DRA webhook" sub="rewrites the request" .blue
rc "ResourceClaim" sub="or ResourceClaimTemplate"
ks "kube-scheduler" sub="DRA allocation" .blue
core "HAMi-Core" sub="same in-container limits" .green
pod -> wh flow=forward
wh -> rc flow=forward
rc -> ks flow=forward
ks -> core flow=forward
```

- NVIDIA, Hygon HCU, AMD and Ascend in one deployment (`deviceVendors`)
- `resourceClaimTemplate: true` lets Kueue admit the Pods. `batch/v1` Jobs are not covered yet
- Needs Kubernetes 1.34+, `DRAConsumableCapacity`, and CDI in containerd or CRI-O

github.com/Project-HAMi/HAMi-DRA

---

## DRA and the schedulers above it

::: grid {cols=3}
::: card {tag=cyan}
### Kueue
Admits ResourceClaimTemplates. Needs the HAMi DeviceClass in `deviceClassMappings`.
:::
::: card {tag=green}
### Volcano
Today: `deviceshare` plus the vGPU device plugin. Gang and queue capacity on shared GPUs.
:::
::: card {tag=yellow}
### KAI Scheduler
Today: GPU fractions with HAMi-Core as the isolation layer.
:::
:::

Open questions for the room: who decides partitioning, the driver or the scheduler? How do quotas count fractional devices?

---

@variant dark
<!--
13:10. Target: 5 minutes. The sim oscillates over 2 minutes, give it time. Then the live isolation demo if the real node is up.
-->

# Wrap-up

@subtitle Two metric families, what to try after the session

---

## Reserved is not used

```pdg
graph layout=row theme=hami gap=70
group alloc "Allocation · scheduler :9395" sub="what was reserved" layout=column gap=18 .blue {
  acard "Per card" sub="hami_gpu_memory_allocated_bytes\nhami_gpu_core_allocated_ratio"
  apod "Per pod" sub="hami_vgpu_memory_allocated_bytes\nhami_gpu_shared_count"
}
group usage "Usage · monitor :9394" sub="what is consumed" layout=column gap=18 .green {
  ucnt "Per container" sub="hami_vgpu_memory_used_bytes\nhami_container_device_utilization_ratio"
  ucard "Per card" sub="hami_host_gpu_memory_used_bytes\nhami_host_gpu_utilization_ratio"
}
alloc -> usage "alloc ≥ used"
```

```bash
./metrics.sh scheduler   # allocation, port 9395
./metrics.sh monitor     # usage, port 9394
```

---

## Two metric sources

::: grid {cols=2}
::: card {tag=cyan}
### Scheduler :9395, allocation
- `gpu_memory_allocated_bytes`
- `gpu_core_allocated_ratio`
- `node_gpu_memory_allocated_ratio`
- `gpu_shared_count`
- `vgpu_memory_allocated_bytes`
- `resource_quota_used`
:::
::: card {tag=green}
### vGPUmonitor :9394, usage
- `vgpu_memory_used_bytes`
- `vgpu_memory_limit_bytes`
- `container_device_utilization_ratio`
- `host_gpu_utilization_ratio`
- `host_gpu_memory_used_bytes`
- `container_last_kernel_elapsed_seconds`
:::
:::

All names start with `hami_`. Same labels: `node`, `device_uuid`, `namespace`, `pod`. Join them in PromQL.

---

## Give the mock a realistic load

```bash
kubectl apply -f sim.yaml      # llm-d-inference-sim, requests oscillate 0 to 5
watch -n 5 "./metrics.sh monitor | grep 'pod=\"sim\"'"
```

```text
hami_container_device_utilization_ratio{pod="sim"} 26.4
hami_node_gpu_memory_allocated_ratio{device_uuid="GPU-mock-1"} 0.73
hami_host_gpu_utilization_ratio{device_uuid="GPU-mock-1"}      20.0
```

- `sim` is a vLLM-compatible inference simulator: utilization moves between 0 and 33 (load x allocated cores)
- Memory stays at 0.9 x the limit, because vLLM preallocates its KV cache

**Question.** Card `GPU-mock-1` shows 73% memory allocated but 20% used. Which number goes on a capacity dashboard, and which on a cost report?

---

## Live: isolation on a real GPU

::: grid {cols=2}
::: card {tag=cyan}
### Ask
`nvidia.com/gpumem: 3000`
:::
::: card {tag=green}
### See
`nvidia-smi` in the Pod reports 3000 MiB total.
:::
:::

Allocating past the limit fails inside the Pod with out of memory. Neighbours keep running.

<!--
Presenter only, real NVIDIA node. This is the part the lab cannot show: HAMi-core enforcement. Pre-recorded fallback if the node is down.
-->

---

## After the session: HAMi WebUI

`metrics.sh` is fine for a terminal, but the HAMi WebUI turns the same numbers into dashboards. It needs a Prometheus in the cluster:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add hami-webui https://project-hami.github.io/HAMi-WebUI
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --version 75.15.1 -n monitoring --create-namespace --set grafana.enabled=false --wait
kubectl apply -f monitoring.yaml   # scrape :9395 and :9394
kubectl apply -f webui-rules.yaml  # translate metric names for the WebUI
helm upgrade --install my-hami-webui hami-webui/hami-webui \
  --set externalPrometheus.enabled=true \
  --set-string externalPrometheus.address="http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090" \
  --set dcgm-exporter.enabled=false \
  -n kube-system --wait
kubectl -n kube-system port-forward svc/my-hami-webui 3000:3000
```

Open http://localhost:3000.

---

## Why `webui-rules.yaml`

![HAMi WebUI cluster overview](assets/containerdays/containerdays-webui-overview.png)

- The WebUI queries vGPUmonitor's metric names (`hami_memory_size`, `hami_core_util`, `hami_container_vgpu_allocated`, ...)
- This lab's scheduler and mock monitor expose the newer byte/ratio names (`hami_gpu_memory_limit_bytes`, `hami_host_gpu_utilization_ratio`, ...)
- The PrometheusRule records one set as the other. Without it every allocation and usage panel stays empty

<!--
Pre-pulling for an offline room: --set image.*.digest="" makes the chart use the v1.3.0 tags, which matters because digest references cannot be re-tagged after kind load.
-->

---

## How the WebUI integrates

```pdg
graph layout=row theme=hami gap=48
user "Browser" sub="port-forward :3000"
group pod "HAMi-WebUI Pod" sub="one container, read-only" layout=column gap=18 .blue {
  vue "Vue app" sub="static assets · :3000"
  apih "Go API" sub="/api/vgpu/v1 · in-process" .blue
  diag "Diagnostics" sub="ready · metrics · :8000"
}
group src "Data sources" layout=column gap=18 {
  k8s "Kubernetes API" sub="nodes · Pods · device ConfigMap"
  prom "Prometheus" sub="HAMi :9395 · :9394 · DCGM"
}
user -> vue
vue -> apih
apih -> k8s "list"
apih -> prom "PromQL"
```

<!--
WebUI v1.2.0+ needs HAMi 2.9.0 metric names. It never schedules or mutates anything; one instance per cluster, put auth in front of it.
-->

---

## Hack on the WebUI

```bash
git clone https://github.com/Project-HAMi/HAMi-WebUI && cd HAMi-WebUI
make bootstrap && make -C server bootstrap   # pnpm deps, Go generators (+ protoc)
make -C server run   # Go API on :8000, uses kubeconfig + server/config/config.yaml
make dev             # Vite on :3000, proxies /api/vgpu/v1 to :8000
make verify && make -C server verify         # before the PR
```

- Point `server/config/config.yaml` at the lab's Prometheus (port-forward `:9090`)
- Go, Node and pnpm versions are pinned in the repo. `git commit -s`

---

## After the session: contribute

::: grid {cols=4}
::: card {tag=cyan}
### HAMi
`make test`. Start in `Fit`, `PatchAnnotations` (`pkg/device/nvidia/device.go`) or `Filter`, `Bind` (`pkg/scheduler/scheduler.go`). `git commit -s`.
:::
::: card {tag=green}
### HAMi-DRA
The webhook that turns `nvidia.com/gpu` requests into DRA ResourceClaims. Needs Kubernetes 1.34+.
:::
::: card {tag=yellow}
### mock-device-plugin
Complete the bind in `Allocate` (a patch is prepared in `hami-mock-monitor/upstream/mock-device-plugin`), or add a vendor.
:::
::: card {tag=red}
### hami-mock-monitor
Other vendors (Ascend, Hygon), a Grafana dashboard for the lab, a published image.
:::
:::

Look for `good first issue`. Open a draft PR before you leave. Disclose AI help in the PR.

---

## Clean up

```bash
kind delete cluster --name hami-lab
```

---

## Where HAMi Is Today

@subtitle Production metrics from CNCF case studies

::: grid {cols=4}
::: card {metric}
0
Driver, kernel, code changes needed
SF Technology
:::
::: card {metric}
1-2 GB
Memory per small-model inference service
KE Holdings
:::
::: card {metric}
4x
GPU utilization: 5-10% to 30-50%
NIO
:::
::: card {metric}
90%
GPU infra managed by HAMi on RTX 4070/4090
Prep Edu
:::
:::

::: notes{ tag="green" }
China Merchants Bank - SNOW Corp. - NIO - KE Holdings - DaoCloud - SF Technology - Prep Education - cncf.io/case-studies
:::

---

@layout ecosystem
## Community & Adopters

@subtitle Devices, integrations, and who uses HAMi

<!--
5k stars, 700k+ pulls, 500+ contributors, 27 countries. 13 device types, 20+ adopters. The QR code links to github.com/Project-HAMi/HAMi.
-->

#### Open Source, CNCF Backed, Production Ready
::: grid {cols=5}
::: card {metric}
5k
Github Stars
:::
::: card {metric}
700k
Docker Pulls
:::
::: card {metric}
500+
Contributors
:::
::: card {metric}
27
Contributor Countries
:::
::: card

![Kubernetes](assets/ecosystem/integrations/kubernetes.png) ![Volcano](assets/ecosystem/integrations/volcano.png) ![Kueue](assets/ecosystem/integrations/kueue.png) ![Koordinator](assets/ecosystem/integrations/koordinator.png) ![KAI Scheduler](assets/ecosystem/integrations/kai-scheduler.png) ![cozystack](assets/ecosystem/integrations/cozystack.svg)
:::
:::

#### Ecosystem & Device Support
::: grid {cols=2}
::: card
![NVIDIA](assets/ecosystem/devices/nvidia.png)

![AMD](assets/ecosystem/devices/amd.png) ![Ascend](assets/ecosystem/devices/ascend.png) ![Cambricon](assets/ecosystem/devices/cambricon.png) ![Hygon](assets/ecosystem/devices/hygon.png) ![Iluvatar](assets/ecosystem/devices/illuvitar.png)
![Metax](assets/ecosystem/devices/metax.png) ![Moore Threads](assets/ecosystem/devices/moorethreads.png) ![Kunlunxin](assets/ecosystem/devices/kunlunxin.png) ![Enflame](assets/ecosystem/devices/enflame.png)

![Biren](assets/ecosystem/devices/biren.png)![AWS](assets/ecosystem/devices/aws.png) ![VastStream](assets/ecosystem/devices/vaststream.png)
:::
:::
:::

#### Adopters
::: grid {cols=2}
::: card
![4Paradigm](assets/ecosystem/adopters/4paradigm.png) ![Baidu](assets/ecosystem/adopters/baiduzhineng.png) ![Baike](assets/ecosystem/adopters/baike.png) ![China Merchants](assets/ecosystem/adopters/chinamerchants.png) ![China Mobile](assets/ecosystem/adopters/chinamobile.png)
![China Unicom](assets/ecosystem/adopters/chinaunicom.png) ![DaoCloud](assets/ecosystem/adopters/daocloud.png) ![Dynamia](assets/ecosystem/adopters/dynamia.png) ![H3C](assets/ecosystem/adopters/h3c.png) ![Huawei](assets/ecosystem/adopters/huawei.png)
![LinkedIn](assets/ecosystem/adopters/linkedin.png) ![MSXF](assets/ecosystem/adopters/msxf.png) ![NIO](assets/ecosystem/adopters/nio.png) ![PPIO](assets/ecosystem/adopters/ppio.png) ![Prep](assets/ecosystem/adopters/prep.png)
![SAP](assets/ecosystem/adopters/sap.png) ![SF Technology](assets/ecosystem/adopters/sftechnology.png) ![Si-Tech](assets/ecosystem/adopters/si-tech.png) ![Snow](assets/ecosystem/adopters/snow.png) ![Viettel](assets/ecosystem/adopters/viettel.png)
:::
:::

---

---

@variant dark

# Thank you

@subtitle github.com/Project-HAMi/HAMi · project-hami.io · lab: github.com/Project-HAMi/hami-workshop

@speaker name="Reza Jelveh" role="Global Market & Solution Architecture, Dynamia AI" github=github.com/fishman linkedin=linkedin.com/in/rezajelveh
@speaker name="Mengxuan Li" role="CTO, Dynamia AI  -  HAMi maintainer"
