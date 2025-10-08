# API Keys
## NVIDIA API Key
You will need an NVIDIA API KEY to call NVIDIA AI Endpoints.  

You can use different model API endpoints with the same API key, so even if you change the LLM specification in `ChatNVIDIA(model=llm_model)` you can still use the same API KEY.

a. Navigate to [https://build.nvidia.com/](https://build.nvidia.com/).

b. Search for **llama-3.3-70b-instruct**  and click the entry. You can also find any other llm for generating the key since it is shared across all NIMs.

![Llama 3.3 70B search entry](./images/llama-33-70b-instruct-search-entry.png)

c. You should now be in the NIM page.

![llama 3.3 nim page](./images/llama-33-model-page.png)

d. Click "View Code" on the top right corner of the page.
![view code](./images/view-code-button.png)

e. Click **Generate API Key** in the window that pops up.

![API key](./images/llama-33-generate_api_key.png)
Log in if you haven't already.

d. Copy your generated API key to a secure location. We will be using it in this blueprint.
