@echo off
setlocal enabledelayedexpansion

:CHOOSE_OPTION
REM Ask user for installation type
echo [33mChoose your preferred installation:[0m
echo [32mA) Fast-Lowvram install (GGUF)[0m
echo [32mB) Unoptimized normal model (bf16)[0m
set /p "CHOICE=Enter your choice (A or B) and press Enter: "

if /i "%CHOICE%"=="A" (
    set "INSTALL_TYPE=fast-lowvram"
) else if /i "%CHOICE%"=="B" (
    set "INSTALL_TYPE=unoptimized"
	set "DOWNLOAD_GGUF=no"
) else (
echo [31mInvalid choice. Please enter A or B.[0m
    goto CHOOSE_OPTION
)

:CHOOSE_FLUX_GGUF
REM Ask user if they want to download FLUX GGUF Model
echo [33mDo you want to download FLUX GGUF Models?[0m
echo [32mA) Q8_0 + T5_Q8 (24GB Vram)[0m
echo [32mB) Q5_K_S + T5_Q5_K_M (16GB Vram)[0m
echo [32mC) Q4_K_S + T5_Q3_K_L (less than 12GB Vram)[0m
echo [32mD) All[0m
echo [32mE) No[0m
set /p "FLUX_GGUF_CHOICE=Enter your choice (A,B,C,D or E) and press Enter: "
	if /i "%FLUX_GGUF_CHOICE%"=="A" (
	set "DOWNLOAD_GGUF=yes"
) else if /i "%FLUX_GGUF_CHOICE%"=="B" (
	set "DOWNLOAD_GGUF=yes"
) else if /i "%FLUX_GGUF_CHOICE%"=="C" (
	set "DOWNLOAD_GGUF=yes"
) else if /i "%FLUX_GGUF_CHOICE%"=="D" (
	set "DOWNLOAD_GGUF=yes"
) else if /i "%FLUX_GGUF_CHOICE%"=="E" (
	set "DOWNLOAD_GGUF=no"
) else (
	echo [31mInvalid choice. Please enter A or B.[0m
	goto CHOOSE_FLUX_GGUF
)

REM Check if 7-Zip is installed and get its path
for %%I in (7z.exe) do set "SEVEN_ZIP_PATH=%%~$PATH:I"
if not defined SEVEN_ZIP_PATH (
    if exist "%ProgramFiles%\7-Zip\7z.exe" (
        set "SEVEN_ZIP_PATH=%ProgramFiles%\7-Zip\7z.exe"
    ) else if exist "%ProgramFiles(x86)%\7-Zip\7z.exe" (
        set "SEVEN_ZIP_PATH=%ProgramFiles(x86)%\7-Zip\7z.exe"
    ) else (
        echo 7-Zip is not installed. Downloading and installing...
        curl -L -o 7z-installer.exe https://www.7-zip.org/a/7z2201-x64.exe
        7z-installer.exe /S
        set "SEVEN_ZIP_PATH=%ProgramFiles%\7-Zip\7z.exe"
        if not exist "%SEVEN_ZIP_PATH%" (
            echo Installation of 7-Zip failed. Please install it manually and try again.
            exit /b 1
        )
        del 7z-installer.exe
    )
)

REM Check and install Git
git --version > NUL 2>&1
if %errorlevel% NEQ 0 (
    echo Installing Git...
    powershell -Command "& {Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.41.0.windows.3/Git-2.41.0.3-64-bit.exe' -OutFile 'Git-2.41.0.3-64-bit.exe'; if ($LASTEXITCODE -ne 0) { exit 1 }}"
    if %errorlevel% NEQ 0 (
        echo Failed to download Git installer.
        exit /b
    )
    start /wait Git-2.41.0.3-64-bit.exe /VERYSILENT
    del Git-2.41.0.3-64-bit.exe
) else (
    echo Git already installed.
)

REM Download ComfyUI
echo [33mDownloading ComfyUI...[0m
curl -L -o ComfyUI_windows_portable_nvidia.7z https://github.com/comfyanonymous/ComfyUI/releases/download/v0.3.27/ComfyUI_windows_portable_nvidia.7z

REM Extract ComfyUI
echo [33mExtracting ComfyUI...[0m
"%SEVEN_ZIP_PATH%" x ComfyUI_windows_portable_nvidia.7z -o"%CD%" -y  >nul 2>&1

REM Check if extraction was successful
if not exist "ComfyUI_windows_portable" (
    echo Extraction failed. Please check the downloaded file and try again.
    exit /b 1
)

REM Delete archive
del /f ComfyUI_windows_portable_nvidia.7z -force


REM Navigate to custom_nodes folder
REM Update ComfyUI
cd ComfyUI_windows_portable\update
..\python_embeded\python.exe -m pip install --upgrade pip  >nul 2>&1
..\python_embeded\python.exe .\update.py ..\ComfyUI\  >nul 2>&1
if exist update_new.py (
  move /y update_new.py update.py
  echo Running updater again since it got updated.
  ..\python_embeded\python.exe .\update.py ..\ComfyUI\ --skip_self_update  >nul 2>&1
)

cd ..

cd python_embeded
echo [33mInstalling xformers...[0m
.\python.exe -s -m pip install xformers >nul 2>&1
.\python.exe -s -m pip install pytorch-pretrained-bert >nul 2>&1
.\python.exe -s -m pip install pytorch-extension >nul 2>&1
echo [33mInstalling NVIDIA Apex...[0m
git clone https://github.com/NVIDIA/apex >nul 2>&1
cd apex
..\python.exe -s -m pip install -e . >nul 2>&1
cd ..\..

cd ComfyUI\custom_nodes

REM Clone ComfyUI-Manager
echo [33mInstalling ComfyUI-Manager...[0m
git clone https://github.com/ltdrdata/ComfyUI-Manager.git >nul 2>&1
echo [33mInstalling additional nodes...[0m
echo   - Impact-Pack
git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack >nul 2>&1
cd ComfyUI-Impact-Pack
git clone https://github.com/ltdrdata/ComfyUI-Impact-Subpack impact_subpack >nul 2>&1
..\..\..\python_embeded\python.exe -s -m pip install -r requirements.txt --no-warn-script-location >nul 2>&1
..\..\..\python_embeded\python.exe -s -m pip install ultralytics --no-warn-script-location >nul 2>&1
cd ..

echo   - GGUF
git clone https://github.com/city96/ComfyUI-GGUF >nul 2>&1
cd ComfyUI-GGUF
..\..\..\python_embeded\python.exe -s -m pip install -r requirements.txt --no-warn-script-location >nul 2>&1
cd ..

echo   - mxToolkit
git clone https://github.com/Smirnov75/ComfyUI-mxToolkit >nul 2>&1

echo   - Custom-Scripts
git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts >nul 2>&1

echo   - KJNodes
git clone https://github.com/kijai/ComfyUI-KJNodes >nul 2>&1
cd ComfyUI-KJNodes
..\..\..\python_embeded\python.exe -s -m pip install -r requirements.txt --no-warn-script-location >nul 2>&1
cd ..

echo   - ComfyUI-VideoHelperSuite
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite >nul 2>&1
cd ComfyUI-VideoHelperSuite
..\..\..\python_embeded\python.exe -s -m pip install -r requirements.txt --no-warn-script-location >nul 2>&1
cd ..

echo   - ComfyUI-Frame-Interpolation
git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation >nul 2>&1
cd ComfyUI-Frame-Interpolation
..\..\..\python_embeded\python.exe -s -m pip install -r requirements-with-cupy.txt --no-warn-script-location >nul 2>&1
cd ..

echo   - rgthree
git clone https://github.com/rgthree/rgthree-comfy >nul 2>&1
cd rgthree-comfy
..\..\..\python_embeded\python.exe -s -m pip install -r requirements.txt --no-warn-script-location >nul 2>&1
cd ..

echo   - ComfyUI-Easy-Use
git clone https://github.com/yolain/ComfyUI-Easy-Use >nul 2>&1
cd ComfyUI-Easy-Use
..\..\..\python_embeded\python.exe -s -m pip install -r requirements.txt --no-warn-script-location >nul 2>&1
cd ..

echo   - ComfyUI_PuLID_Flux_ll
git clone https://github.com/lldacing/ComfyUI_PuLID_Flux_ll >nul 2>&1
cd ComfyUI_PuLID_Flux_ll
..\..\..\python_embeded\python.exe -s -m pip install -r requirements.txt --no-warn-script-location >nul 2>&1
curl -L -o "insightface-0.7.3-cp310-cp310-win_amd64.whl" https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/others/insightface-0.7.3-cp310-cp310-win_amd64.whl?download=true  >nul 2>&1
curl -L -o "insightface-0.7.3-cp311-cp311-win_amd64.whl" https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/others/insightface-0.7.3-cp311-cp311-win_amd64.whl?download=true  >nul 2>&1
curl -L -o "insightface-0.7.3-cp312-cp312-win_amd64.whl" https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/others/insightface-0.7.3-cp312-cp312-win_amd64.whl?download=true  >nul 2>&1
..\..\..\python_embeded\python.exe -m pip install --use-pep517 facexlib  >nul 2>&1
..\..\..\python_embeded\python.exe -m pip install git+https://github.com/rodjjo/filterpy.git  >nul 2>&1
..\..\..\python_embeded\python.exe -m pip install onnxruntime==1.19.2 onnxruntime-gpu==1.15.1 insightface-0.7.3-cp310-cp310-win_amd64.whl  >nul 2>&1
..\..\..\python_embeded\python.exe -m pip install onnxruntime==1.19.2 onnxruntime-gpu==1.15.1 insightface-0.7.3-cp311-cp311-win_amd64.whl  >nul 2>&1
..\..\..\python_embeded\python.exe -m pip install onnxruntime==1.19.2 onnxruntime-gpu==1.17.1 insightface-0.7.3-cp312-cp312-win_amd64.whl  >nul 2>&1
cd ..

echo   - ComfyUI-HunyuanVideoMultiLora
git clone https://github.com/facok/ComfyUI-HunyuanVideoMultiLora >nul 2>&1

cd ..
cd models
REM Download VAE file
echo [33mDownloading VAE file...[0m
cd vae
curl -L -o wan_2.1_vae.safetensors https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors?download=true

cd ..

REM Download CLIP files
echo [33mDownloading CLIP files...[0m
cd clip
curl -L -o "umt5_xxl_fp8_e4m3fn_scaled.safetensors" https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors?download=true
cd ..

REM Download Diffusion models files
cd diffusion_models
if "%INSTALL_TYPE%"=="unoptimized" (
	echo [33mDownloading diffusion models file...[0m
	echo T2V Quant Model :
	curl -L -o wan2.1_i2v_480p_14B_bf16.safetensors https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_i2v_480p_14B_bf16.safetensors?download=true
	echo I2V Quant Model :
	curl -L -o wan2.1_t2v_1.3B_bf16.safetensors https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_t2v_1.3B_bf16.safetensors?download=true
)
if "%DOWNLOAD_GGUF%"=="yes" (
    echo [33mDownloading GGUF T2V Quant Model...[0m
    if /i "%FLUX_GGUF_CHOICE%"=="A" (
	curl -L -o wan2.1-t2v-14b-Q8_0.gguf https://huggingface.co/city96/Wan2.1-T2V-14B-gguf/resolve/main/wan2.1-t2v-14b-Q8_0.gguf?download=true
	) else if /i "%FLUX_GGUF_CHOICE%"=="B" (
	curl -L -o wan2.1-t2v-14b-Q5_K_M.gguf https://huggingface.co/city96/Wan2.1-T2V-14B-gguf/resolve/main/wan2.1-t2v-14b-Q5_K_M.gguf?download=true
	) else if /i "%FLUX_GGUF_CHOICE%"=="C" (
	curl -L -o wan2.1-t2v-14b-Q3_K_S.gguf https://huggingface.co/city96/Wan2.1-T2V-14B-gguf/resolve/main/wan2.1-t2v-14b-Q3_K_S.gguf?download=true
	) else if /i "%FLUX_GGUF_CHOICE%"=="D" (
	curl -L -o wan2.1-t2v-14b-Q8_0.gguf https://huggingface.co/city96/Wan2.1-T2V-14B-gguf/resolve/main/wan2.1-t2v-14b-Q8_0.gguf?download=true
	curl -L -o wan2.1-t2v-14b-Q5_K_M.gguf https://huggingface.co/city96/Wan2.1-T2V-14B-gguf/resolve/main/wan2.1-t2v-14b-Q5_K_M.gguf?download=true
	curl -L -o wan2.1-t2v-14b-Q3_K_S.gguf https://huggingface.co/city96/Wan2.1-T2V-14B-gguf/resolve/main/wan2.1-t2v-14b-Q3_K_S.gguf?download=true
	)
)
if "%DOWNLOAD_GGUF%"=="yes" (
    echo [33mDownloading GGUF I2V Quant Model...[0m
    if /i "%FLUX_GGUF_CHOICE%"=="A" (
	curl -L -o wan2.1-i2v-14b-480p-Q8_0.gguf https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main/wan2.1-i2v-14b-480p-Q8_0.gguf?download=true
	) else if /i "%FLUX_GGUF_CHOICE%"=="B" (
	curl -L -o wan2.1-i2v-14b-480p-Q5_K_M.gguf https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main/wan2.1-i2v-14b-480p-Q5_K_M.gguf?download=true
	) else if /i "%FLUX_GGUF_CHOICE%"=="C" (
	curl -L -o wan2.1-i2v-14b-480p-Q3_K_S.gguf https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main/wan2.1-i2v-14b-480p-Q3_K_S.gguf?download=true
	) else if /i "%FLUX_GGUF_CHOICE%"=="D" (
	curl -L -o wan2.1-i2v-14b-480p-Q8_0.gguf https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main/wan2.1-i2v-14b-480p-Q8_0.gguf?download=true
	curl -L -o wan2.1-i2v-14b-480p-Q5_K_M.gguf https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main/wan2.1-i2v-14b-480p-Q5_K_M.gguf?download=true
	curl -L -o wan2.1-i2v-14b-480p-Q3_K_S.gguf https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main/wan2.1-i2v-14b-480p-Q3_K_S.gguf?download=true
	)
)
cd ..

REM Download clip vision
cd clip_vision
echo [33mDownloading clip vision file...[0m
curl -L -o clip_vision_h.safetensors https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors?download=true
cd ..

REM Download upscale model
echo [33mDownloading upscale models...[0m
cd upscale_models
curl -L -o 4x_foolhardy_Remacri.pth https://huggingface.co/FacehugmanIII/4x_foolhardy_Remacri/resolve/main/4x_foolhardy_Remacri.pth?download=true

cd ..\..

mkdir .\user\default
echo [33mDownloading comfy settings...[0m
cd user\default
curl -L -o comfy.settings.json https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/others/comfy.settings.json?download=true
echo [33mDownloading comfy workflow...[0m
mkdir .\workflows
cd workflows
curl -L -o "UmeAiRT-WAN21_workflow.7z" https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/workflows/UmeAiRT-WAN21_workflow.7z?download=true
"%SEVEN_ZIP_PATH%" x "UmeAiRT-WAN21_workflow.7z" -o"%CD%" -y   >nul 2>&1
del /f "UmeAiRT-WAN21_workflow.7z" -force   >nul 2>&1
cd ..\..\..\..

curl -L -o "UmeAiRT-WAN2.1-Missing_nodes.bat" "https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/UmeAiRT-WAN2.1-Missing_nodes.bat?download=true"
curl -L -o "UmeAiRT-WAN2.1-Model_downloader.bat" "https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/UmeAiRT-WAN2.1-Model_downloader.bat?download=true"

REM Final steps based on user choice
if "%INSTALL_TYPE%"=="fast-lowvram" (
    echo Downloading special run file for fast-lowvram...
    curl -L -o "run_nvidia_gpu-LOWVRAM.bat" "https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/scripts/run_nvidia_gpu-LOWVRAM.bat?download=true"
    echo ComfyUI and FLUX installed. Running ComfyUI...
    call "run_nvidia_gpu-LOWVRAM.bat"
) else (
    echo ComfyUI and FLUX installed. HAVE FUN ;)
    call "run_nvidia_gpu.bat"
)