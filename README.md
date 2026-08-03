# Multi-Agent Debate for Programming Assessments

This project serves as the verification methodology for the Question Generator LLM. 
It uses three different LLMs acting as students to simulate a peer-review 
environment. Each LLM completes the programming assessment independently, and then 
they grade and peer-review each other's answers.

After the LLMs submit their work, a grading pipeline runs to evaluate the 
submissions. This pipeline determines which LLM is the best individual solver and 
analyzes whether the multi-agent debate process successfully improves the overall 
correctness of the assessment.

## Architecture

The system is designed around a secure, locally deployed environment to ensure 
data privacy and bypass reliance on commercial cloud APIs. The architecture consists 
of several core components:

### Local Inference Engine: 

Executes student models entirely on local hardware.

### Multi-Agent Consensus Module:

Adapts the N-Version Programming (NVP) paradigm to generate multiple independent LLM 
agents. These agents debate and evaluate the same tasks to mitigate isolated 
failures and value-level hallucinations (such as strictly typed JSON validation 
errors).

### Grading & Voting Pipeline: 

Utilizes a majority voting mechanism to evaluate the independent agent submissions, 
determine the most accurate solver, and analyze if the multi-agent debate improves 
overall factuality.

## Tech Stack

### Languages: 

Python is the primary language used to orchestrate the evaluation process and 
execute the grading pipeline.

### Infrastructure & Orchestration: 

Docker and Docker Compose are utilized to run the entire system and manage the 
isolated containers for each LLM agent.

### Generative Models: 

This project utilizes three generative Large Language Models (LLMs) to power the 
multi-agent consensus module. These models have been selected to provide diverse 
reasoning capabilities within the local environment.

#### GPT-OSS

- openai/gpt-oss-20b
  - Number of Parameters: 21B/3.6B
  - Tensor Type: BF16/U8
  - Context Length: 131,072
  - Capabilities: It is an open-weight model released by OpenAI under the Apache 2.0 license, optimized for lower-latency inference and deployability on consumer hardware. It supports reasoning level configuration, fine-tuning, and agentic capabilities including function calling, tool use, and structured outputs.


#### Qwen-Coder

  - NVFP4/Qwen3-Coder-30B-A3B-Instruct-FP4
  - Number of Parameters: 30.5B/3.3B
  - Tensor Type: BF16 (FP4 Quantization)
  - Context Length: 262,144
  - Capabilities: This model features advanced long-horizon reinforcement learning on SWE-Bench and similar benchmarks. It has exceptional agentic capabilities for real-world software engineering tasks.

#### DeepSeek-Coder

- deepseek-ai/DeepSeek-Coder-V2-Lite-Instruct
  - Number of Parameters: 16B/2.4B
  - Tensor Type: BF16
  - Context Length: 128,000
  - Capabilities: This is a powerful and efficient open-source code language model that generates and understands code in a vast number of programming languages. It is designed to handle a wide range of coding tasks, including code completion, bug fixing, and generating complex code snippets from natural language prompts, and also possesses strong mathematical reasoning capabilities.

## Installation

### Prerequisites

- Docker Compose version v5.0.1 
- Python 3.12.3
- VRAM requirement: At least 128G Unified Memory or VRAM is Required

### Environment Setup

1. Clone the Repository:

```shell
git clone https://github.com/Xiaobai2-2022/multi-agent-debate
```

2. Configure Environment Variables:

The Docker Compose environment relies on an .env file to 
securely manage your Hugging Face authentication and model 
configurations.

   - Copy the example environment file:

```shell
cp .env.example .env
```

  - Open the `.env` file and populate it. You must provide a valid Hugging Face access token (`HF_TOKEN`) because you are utilizing models like Qwen3 that may require license agreements or authentication.

  - Note: Ensure your .env file is added to your .gitignore to prevent committing secrets to version control.

## Build & Run

Start the LLM Services:

  - Make `start_llms.sh` executable

```shell
chmod +x start_llms.sh
```
  
  - Run `start_llms.sh`

```shell
./start_llms.sh
```
