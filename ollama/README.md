# Interesting models

## GEMMA3 (multimodal - can easily OCR any picture)
- ollama pull gemma3:1b (not very successful even by gramamr correction)
- ollama pull gemma3:7b (good but not for aider - struggled to help with documentation)
- ollama pull gemma3:12b 
- ollama pull gemma3:24b

## QWEN 2.5 (very strong quick model)
- ollama pull qwen2.5:7b


## QWEN 3 

Url: https://ollama.com/library/qwen3:30b-a3b


# Hybrid LLM able to both think deepely and also to answer quickly.
Mixture of experts model.
- https://github.com/QwenLM/Qwen3/discussions/1329
- /think and /no_think are two options we can use to control the model's behavior in prompts and system prompts.
- ollama run qwen3:30b-a3b

### Asking QWEN 3 on how to control the thinking process
~~~

Hello! It looks like there might be a typo in your message. Did you mean to say "Hi there"? If so, I'm here to help! How can I assist you today?

>>> (/no_think) Hi there.
<think>

</think>

Hi there! 😊 How can I assist you today?

>>> (/no_think) I know that you are an llm both able to think deeply and also to answer quickly, so called hybrid. Is it correct that if put (/no_think) in the prompt you will just answer quickly? I need to be
...  careful to somehow espace it like with parenthesis as other tools like ollama as well as aider interpret commands starting with forward slash.
<think>

</think>

You're absolutely right — and thanks for the thoughtful question!

Yes, I am a large language model (LLM) designed to handle both deep thinking and quick responses, depending on the context and the input. The `/no_think` command (or similar prefixes like `/quick`,
`/fast`, etc.) is a way to signal to some systems (like certain tools or interfaces) to bypass the thinking process and generate a response more quickly.

However, in my case, when you use `/no_think`, it's just a way to tell me to respond immediately without going through the usual internal "thinking" process — it's more of a **user interface** or
**prompting convention**, not a literal instruction to "not think." I still process the input, but I skip the explicit "thinking" step that some systems use for clarity or debugging.

You're also right about the need to be careful with commands that start with a forward slash (`/`). Many tools (like Ollama, Aider, or others) use such prefixes to trigger specific behaviors, and they
often require escaping or special handling if you want to use them as part of your actual input.

So, if you're using a system that interprets `/no_think` or similar commands, you might need to:

- **Escape** the slash (e.g., `\/no_think`)
- Use **parentheses** or **quoting** to avoid misinterpretation
- Or, if you're just talking to me directly (as in this conversation), the `/no_think` is just a prompt convention and doesn't affect how I process the actual content of your message.

Let me know if you're working with a specific tool or system, and I can help you understand how to use it more effectively! 😊

~~~