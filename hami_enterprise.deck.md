---
title: "From Project to Production: HAMi and Viettel Cloud"
footer: HAMi - Heterogeneous AI Computing Virtualization Middleware
paginate: true
---

@variant dark
@kicker A CNCF Incubation Project

# HAMi and Viettel Cloud: From Project to Production

@subtitle Fractional GPU Virtualization for Multi-tenant AI Notebooks
@speaker name="Reza Jelveh" role="Solution Architect, Dynamia AI  -  Makers of HAMi" github=github.com/fishman twitter=@rezajelveh
@speaker name="The Anh Nguyen" role="Solutions Engineer, Viettel" github=github.com/ntheanh201

---

## What You'll Learn

- **GPU Sharing Mechanics:** How DRA and HAMi interact with the Kubernetes scheduler, and where the abstraction breaks down
- **Production Blueprint:** Viettel Cloud's deployment of AI Notebooks with fractional GPUs, including isolation techniques and real utilization numbers
- **Problem → Solution → Implementation:** The full pipeline from identifying GPU underutilization to deploying a production vGPU platform at telco scale

---

# Part 1: The Problem

@subtitle GPU underutilization, atomic allocation, multi-tenant contention

---

## The Problem

Kubernetes treats GPUs as atomic resources, forcing over-provisioning and low utilization in multi-tenant AI Notebooks. DRA and HAMi's vGPU virtualization solve this, but only if implemented correctly.

- GPUs are **allocated whole**: a 1GB inference task blocks an entire 80GB device
- **Over-provisioning** is the default: request peak, burn budget, idle silicon
- **DRA** (Dynamic Resource Allocation) enables structured GPU requests but doesn't solve sharing
- **HAMi** provides the fractional GPU layer DRA needs for fine-grained allocation

---

## What is HAMi

![Before HAMi](assets/hami_intro/before-hami.png)

---

## What is HAMi

![After HAMi](assets/hami_intro/after-hami.png)

---

# Part 2: The Solution

@subtitle How DRA + HAMi implement fractional GPU allocation and scheduling

---

## HAMi Capabilities

::: grid {cols=2}
::: card
### {icon:layers cls=accent-primary} Heterogeneous Management

Manage and schedule GPU, NPU, MLU, and other accelerators in one workflow.
:::
::: card
### {icon:shield-check cls=accent-primary} Hard Isolation

Slice memory and compute precisely with hard isolation at runtime.
:::
::: card
### {icon:git-branch cls=accent-contrast} Advanced Scheduling

Use binpack, spread, and topology-aware policies for better placement.
:::
::: card
### {icon:box cls=accent-primary} Kubernetes Native

Work with Kubernetes APIs, DRA, and CDI for easier adoption.
:::
::: card
### {icon:gauge cls=accent-primary} Resource Isolation & QoS

Control memory and core quotas for fairer and more stable sharing.
:::
::: card
### {icon:chart-bar cls=accent-contrast} Unified Monitoring

Provide consistent metrics and visibility across device vendors.
:::
:::

---

## The GPU Challenge

@subtitle Supply and demand are polarized

::: grid {cols=2}
::: card {tag=red}
### Supply Side

- Many GPU manufacturers (NVIDIA, AMD, Intel, Huawei Ascend)
- Specifications vary widely
- Centralized management is difficult
- Resource scheduling is rough
:::
::: card {tag=yellow}
### Demand Side

- GPU resources are scarce
- Users are cost-sensitive
- Inference demands are fragmented
- Utilization is often low
:::
:::

---

## GPU Management Pain Points

- {icon:server cls=accent-secondary} No resource pool, no overall scheduling, no management plane
- {icon:layers cls=accent-secondary} GPUs scattered, difficult to manage centrally
- {icon:lock cls=accent-secondary} No GPU sharing - 1 GPU per task minimum
- {icon:chart-bar cls=accent-secondary} Resource allocation is inflexible, cannot specify size/type
- {icon:triangle-alert cls=accent-secondary} No GPU over-division, wasted capacity

---

## What is HAMi

Heterogeneous AI Computing Virtualization Middleware

- {icon:zap cls=accent-primary} Pluggable, lightweight, deploys in any Kubernetes environment
- {icon:layers cls=accent-primary} Virtualizes heterogeneous AI chips (NVIDIA, Ascend, Cambricon, Hygon, Iluvatar)
- {icon:share cls=accent-primary} GPU sharing - multiple tasks share one GPU
- {icon:settings-2 cls=accent-primary} Rich scheduling strategies: binpack, spread, priority, topology-aware
- {icon:shield-check cls=accent-primary} CNCF Incubation project, 80+ contributors, 100+ enterprise adopters

---

## GPU Sharing

@subtitle Dynamic fine-grained device slicing

- **All NVIDIA series** supported
- **Fine-grained:** as small as 1MB device memory, 1% computing cores
- **Transparent to tasks** - no code changes required
- **Hard resource isolation** inside containers

HAMi provides device sharing by dynamic device slicing. A task allocates a portion of GPU, leaving the rest for other tasks.

---

## How GPU Sharing Works

HAMi-Core uses **symbolic hijacking** inside containers:

| Requirement | Specification |
|-------------|---------------|
| NVIDIA driver | >= 440 |
| CUDA | >= 10.2 |
| Device Memory isolation | Yes |
| Core utilization limit | Yes |
| Fault isolation | Yes |
| Transparent to GPU tasks | Yes |

---

## GPU Utilization Impact

HAMi enables elastic GPU memory scaling: idle tasks swap to host RAM, freeing device memory for active workloads:

::: card
```seaborn
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

fig, ax = plt.subplots(figsize=(8, 2.8))

fg = plt.rcParams["text.color"]
dimmed = plt.rcParams["xtick.color"]
cmap = plt.get_cmap("Paired")
danger = cmap(4.5 / 12)
danger_bright = cmap(5 / 12)
elastic = cmap(2.5 / 12)
base = cmap(0.5 / 12)
ax.set_facecolor("none")
fig.patch.set_alpha(0)

r = 0.14
bs = f"round,pad={r}"

# Row 1: base=8, spike=3
ax.barh(1, 8, color=base, height=0.65)
ax.barh(1, 3, left=8, color=danger, height=0.65)
ax.plot([10, 10], [0.62, 1.38], color=danger, linewidth=2.5, solid_capstyle="butt")

# Row 2: base=8, spike=7
ax.barh(0, 8, color=base, height=0.65)
ax.barh(0, 7, left=8, color=elastic, height=0.65)
ax.plot([10, 10], [-0.38, 0.38], color=fg, linewidth=1.5, linestyle="--")
ax.plot([15, 15], [-0.38, 0.38], color=fg, linewidth=1.5, linestyle="--")

ax.set_xlim(0, 15.2)
ax.spines[["top", "right", "left", "bottom"]].set_visible(False)
ax.tick_params(left=False, bottom=False, labelleft=False, labelbottom=False)

ax.text(0, 1.38, "Without HAMi", ha="left", va="bottom", fontsize=10, color=fg, fontweight="bold")
ax.text(0, 0.38, "With HAMi: Elastic Scaling", ha="left", va="bottom", fontsize=10, color=fg, fontweight="bold")

ax.text(4, 1, "Normal base load", ha="center", va="center", fontsize=9, color=fg, fontweight="bold")
ax.text(9.5, 1, "Traffic spike", ha="center", va="center", fontsize=7.5, color=dimmed, fontweight="bold")
ax.text(10, 1.42, "10 GB limit", ha="center", va="bottom", fontsize=8, color=danger_bright, fontweight="bold")

ax.text(4, 0, "Normal base load", ha="center", va="center", fontsize=9, color=fg, fontweight="bold")
ax.text(11.5, 0, "Traffic spike", ha="center", va="center", fontsize=7.5, color=dimmed, fontweight="bold")
ax.text(10, -0.42, "10 GB\nsoft limit", ha="center", va="top", fontsize=7.5, color=dimmed)
ax.text(15, -0.42, "15 GB\nburst", ha="center", va="top", fontsize=7.5, color=dimmed)
```
:::

:::card
```seaborn
import matplotlib.pyplot as plt

fig, ax = plt.subplots(figsize=(8, 2.8))

fg = plt.rcParams["text.color"]
dimmed = plt.rcParams["xtick.color"]
cmap = plt.get_cmap("Paired")
green = cmap(2.5 / 12)
blue = cmap(0.5 / 12)
red = cmap(4.5 / 12)
grey = "#9ca3af"
sleep_bg = "#374151"

ax.set_facecolor("none")
fig.patch.set_alpha(0)

# Top: IDLE(25) + EXECUTING(50) + IDLE(25)
ax.barh(1, 25, color=grey, height=0.65)
ax.barh(1, 50, left=25, color=green, height=0.65)
ax.barh(1, 25, left=75, color=grey, height=0.65)

# Bottom: EXECUTING(25) + SLEEP(50) + EXECUTING(25)
ax.barh(0, 25, color=blue, height=0.65)
ax.barh(0, 50, left=25, color=sleep_bg, height=0.65)
ax.barh(0, 25, left=75, color=blue, height=0.65)

# Segment dividers
for x in [25, 75]:
    ax.plot([x, x], [0.62, 1.38], color=fg, linewidth=0.8, linestyle="--")
    ax.plot([x, x], [-0.38, 0.62], color=fg, linewidth=0.8, linestyle="--")

ax.set_xlim(0, 100)
ax.spines[["top", "right", "left", "bottom"]].set_visible(False)
ax.tick_params(left=False, bottom=False, labelleft=False, labelbottom=False)

# Side labels
ax.text(0, 1.38, "HIGH PRIORITY", ha="left", va="bottom", fontsize=10, color=green, fontweight="bold")
ax.text(0, 0.38, "LOW PRIORITY", ha="left", va="bottom", fontsize=10, color=blue, fontweight="bold")

# Top bar labels
ax.text(12.5, 1, "IDLE", ha="center", va="center", fontsize=9, color=fg)
ax.text(50, 1, "EXECUTING", ha="center", va="center", fontsize=9, color=fg, fontweight="bold")
ax.text(87.5, 1, "IDLE", ha="center", va="center", fontsize=9, color=fg)

# Bottom bar labels
ax.text(12.5, 0, "EXECUTING", ha="center", va="center", fontsize=9, color=fg)
ax.text(50, 0, "SLEEP", ha="center", va="center", fontsize=9, color=red, fontweight="bold")
ax.text(87.5, 0, "EXECUTING", ha="center", va="center", fontsize=9, color=fg)

ax.text(50, -0.35, "CUDA-KERNEL BOUNDARY", ha="center", va="top", fontsize=7, color=red)
```
:::
---

## Priority Preemption

High-priority tasks preempt low-priority ones at CUDA kernel boundaries: no wasted compute, clean context switch:

:::card
```seaborn
import matplotlib.pyplot as plt

fig, ax = plt.subplots(figsize=(8, 2.8))

fg = plt.rcParams["text.color"]
dimmed = plt.rcParams["xtick.color"]
cmap = plt.get_cmap("Paired")
green = cmap(2.5 / 12)
blue = cmap(0.5 / 12)
red = cmap(4.5 / 12)
grey = "#9ca3af"
sleep_bg = "#374151"

ax.set_facecolor("none")
fig.patch.set_alpha(0)

# Top: IDLE(25) + EXECUTING(50) + IDLE(25)
ax.barh(1, 25, color=grey, height=0.65)
ax.barh(1, 50, left=25, color=green, height=0.65)
ax.barh(1, 25, left=75, color=grey, height=0.65)

# Bottom: EXECUTING(25) + SLEEP(50) + EXECUTING(25)
ax.barh(0, 25, color=blue, height=0.65)
ax.barh(0, 50, left=25, color=sleep_bg, height=0.65)
ax.barh(0, 25, left=75, color=blue, height=0.65)

# Segment dividers
for x in [25, 75]:
    ax.plot([x, x], [0.62, 1.38], color=fg, linewidth=0.8, linestyle="--")
    ax.plot([x, x], [-0.38, 0.62], color=fg, linewidth=0.8, linestyle="--")

ax.set_xlim(0, 100)
ax.spines[["top", "right", "left", "bottom"]].set_visible(False)
ax.tick_params(left=False, bottom=False, labelleft=False, labelbottom=False)

# Side labels
ax.text(0, 1.38, "HIGH PRIORITY", ha="left", va="bottom", fontsize=10, color=green, fontweight="bold")
ax.text(0, 0.38, "LOW PRIORITY", ha="left", va="bottom", fontsize=10, color=blue, fontweight="bold")

# Top bar labels
ax.text(12.5, 1, "IDLE", ha="center", va="center", fontsize=9, color=fg)
ax.text(50, 1, "EXECUTING", ha="center", va="center", fontsize=9, color=fg, fontweight="bold")
ax.text(87.5, 1, "IDLE", ha="center", va="center", fontsize=9, color=fg)

# Bottom bar labels
ax.text(12.5, 0, "EXECUTING", ha="center", va="center", fontsize=9, color=fg)
ax.text(50, 0, "SLEEP", ha="center", va="center", fontsize=9, color=red, fontweight="bold")
ax.text(87.5, 0, "EXECUTING", ha="center", va="center", fontsize=9, color=fg)

ax.text(50, -0.35, "CUDA-KERNEL BOUNDARY", ha="center", va="top", fontsize=7, color=red)
```
:::

---

## Memory Oversubscription

@layout compare

::: card {tag=compare}
### Before

23GB Device Memory hosts **1** 13B inference model
:::

::: arrow

{icon:arrow-right cls=accent-primary size=48}
:::

::: card {tag=compare}
### After

23GB Device + 46GB virtual memory hosts **3** 13B inference models
:::

::: notes{ tag="green" }
GPU memory automatically swapped to host RAM for idle tasks. Typical scenario: model loading and inference serving.
:::

---

## GPU Sharing Parameters

- : memory size per GPU. Defaults to all available if not set
- : compute percentage per GPU. 0-100 range.

---

## Scheduling Policies

::: grid {cols=2}
::: card {tag=cyan}
### {icon:arrow-up cls=accent-primary} Priority-based

High-priority pods pause lower-priority tasks. Set via  env var.
:::
::: card {tag=green}
### {icon:gauge cls=accent-contrast} Binpack & Spread

Binpack minimizes fragments. Spread distributes evenly across nodes/devices.
:::
::: card {tag=yellow}
### {icon:git-branch cls=accent-contrast} Topology-aware

NVLink-aware scheduling for multi-GPU efficiency. 25GB/s-1800GB/s vs PCIe 16GB/s.
:::
::: card {tag=cyan}
### {icon:crosshair cls=accent-primary} Device-specific

Specify exact GPU models or specific device UUIDs for task placement.
:::
:::

---

@layout two-col

## Scheduling Strategies

![Binpack vs Spread scheduling](assets/hami_intro/binpack_spread.png)

@col

![NUMA topology-aware scheduling](assets/hami_intro/topology_numa.png)

---

## Specify Device Type

HAMi supports targeting or avoiding specific GPU models:

Schedule tasks to specific GPU models or avoid certain types entirely.

---

## GPU Sharing Methods Compared

| Method | Multi-vendor | Isolation | Fragmentation | Overhead |
|--------|:---:|:---:|:---:|:---:|
| HAMi vGPU | {icon:check cls=accent-primary} | Strong | Low | Low |
| CUDA Streams | {icon:x cls=accent-secondary} | Weak | High | Low |
| MPS | {icon:x cls=accent-secondary} | Medium | Low | Medium |
| Time-slicing | {icon:x cls=accent-secondary} | Weak | High | Low |
| MIG | {icon:x cls=accent-secondary} | Strong | High | N/A |
| NVIDIA vGPU | {icon:x cls=accent-secondary} | Strong | Low | High |

---

## HAMi vs Other Projects

| Feature | HAMi | NVIDIA device-plugin | NVIDIA DRA driver |
|---------|:---:|:---:|:---:|
| Multi-vendor GPUs | {icon:check cls=accent-primary} | {icon:x cls=accent-secondary} | {icon:x cls=accent-secondary} |
| GPU sharing | {icon:check cls=accent-primary} | {icon:check cls=accent-primary} | {icon:check cls=accent-primary} |
| Flexible scheduling | {icon:check cls=accent-primary} | {icon:x cls=accent-secondary} | {icon:x cls=accent-secondary} |
| Dynamic MIG | {icon:check cls=accent-primary} | {icon:x cls=accent-secondary} | {icon:x cls=accent-secondary} |
| Memory oversubscription | {icon:check cls=accent-primary} | {icon:x cls=accent-secondary} | {icon:x cls=accent-secondary} |
| Topology-aware | {icon:check cls=accent-primary} | {icon:x cls=accent-secondary} | {icon:x cls=accent-secondary} |
| Heterogeneous devices | {icon:check cls=accent-primary} | {icon:x cls=accent-secondary} | {icon:x cls=accent-secondary} |

---

# Part 3: Viettel Cloud

@subtitle Production deployment of fractional GPUs for AI Notebooks at telco scale

---

## Viettel Cloud: AI Notebooks

Multi-tenant data science platform serving hundreds of users:

- **Before HAMi:** 1 GPU per notebook: 30% average utilization, long queue times
- **With HAMi:** fractional vGPUs, multiple notebooks per physical GPU
- **Workload mix:** Jupyter notebooks, model training, batch inference, RAG pipelines
- **Scale:** telco-grade infrastructure, 24/7 SLA requirements

---

## Deployment Architecture

- HAMi scheduler + device plugin deployed via Helm on Viettel Kubernetes clusters
- DRA resource claims structured per-namespace, per-user quota enforced at scheduler level
- Prometheus + Grafana dashboards: per-tenant GPU utilization, memory pressure, preemption events
- Node problem detector + HAMi health checks for GPU fault detection

---

## Production Bottlenecks

Moving from test to production at scale:

- **Cold start latency:** container images + CUDA context init: mitigated via pre-warmed node pools
- **Memory fragmentation:** small vGPUs leave unusable gaps: binpack scheduling active by default
- **Noisy neighbor:** compute-bound tasks starve latency-sensitive inference: priority + preemption
- **Driver compatibility:** NVIDIA driver minimum 440, CUDA >= 10.2: enforced at admission
- **Monitoring gaps:** GPU telemetry at vGPU granularity required custom Prometheus exporters

---

## Observability

HAMi provides built-in monitoring dashboards (Grafana + Prometheus):

- **K8s scheduling dimension:** vGPU task bindings, task-to-GPU relationships
- **GPU device dimension:** real computing power and memory usage during runtime
- Community best-practice monitoring dashboard included

---

## Applicable Scenarios

::: grid {cols=2}
::: card {tag=green}
### {icon:globe cls=accent-primary} Online Inference

10 services share one GPU. Activate on-demand, low-frequency services share resources. Significantly reduces GPU costs.
:::
::: card {tag=cyan}
### {icon:git-compare-arrows cls=accent-contrast} A/B Testing

Virtual GPU memory reduces hardware requirements. Original + experimental models share a single GPU.
:::
:::

::: grid {cols=2}
::: card {tag=yellow}
### {icon:refresh-cw cls=accent-contrast} Mixed Train/Infer

Inference gets priority, training fills gaps. When inference idle, cached training runs. Flexible queue-based scheduling.
:::
::: card {tag=cyan}
### {icon:zap cls=accent-primary} LLM Optimization

Multiple small models (embedding, reranker, generator) share GPUs. 4 threads → 8 threads on same hardware.
:::
:::

---

## Ecosystem Integrations

| Project | Integration |
|---------|-------------|
| Volcano | Batch scheduling for HPC/AI workloads (CNCF) |
| Koordinator | Colocation of microservices, AI, big data |
| KEDA | Event-driven autoscaling |
| Prometheus + Grafana | Monitoring and observability |
| Helm | One-command deployment |

---

## HAMi Community

| Metric | Value |
|--------|-------|
| Contributors | 80+ |
| Enterprise adopters | 100+ |
| CNCF Status | Incubation + CNAI Landscape |
| Focus | AI Infra + Heterogeneous AI Management |

The only open-source project focused on AI Infrastructure and heterogeneous AI management in CNCF.

---

## About HAMi

- {icon:git-fork cls=accent-primary} github.com/Project-HAMi/HAMi
- {icon:globe cls=accent-primary} project-hami.io
- {icon:users cls=accent-primary} 80+ contributors, 100+ enterprise adopters
- {icon:shield-check cls=accent-primary} CNCF Incubation Project

Community edition is free and open-source. Enterprise edition available with additional features and support.

---

@kicker Thank You

# Questions?

@speaker name="Reza Jelveh" role="Solution Architect, Dynamia AI  -  Makers of HAMi" github=github.com/fishman twitter=@rezajelveh
@speaker name="Anh Nguyen" role="Solutions Engineer, Viettel"
