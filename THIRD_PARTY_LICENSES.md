# Third-Party Licenses

This document lists third-party projects and assets that the PhotonFrame - VideoKit installer downloads or references. Please review the upstream licenses before using the software.

## Microsoft Core Fonts - Impact
- Source: https://downloads.sourceforge.net/corefonts/
- License: Microsoft Core Fonts EULA (proprietary, non-redistributable except via original installer).
- Notes: impact32.exe is downloaded only after you accept the license during installation.
- PhotonFrame - VideoKit does not redistribute the Impact font. The installer only downloads the original impact32.exe from the official Core Fonts mirror after you accept the Microsoft EULA.

## Real-ESRGAN (PyTorch)
- Repository: https://github.com/xinntao/Real-ESRGAN
- License: BSD 3-Clause (see upstream LICENSE file).

## Real-ESRGAN NCNN / RealCUGAN NCNN
- Repository: https://github.com/xinntao/Real-ESRGAN-ncnn-vulkan and https://github.com/nihui/realcugan-ncnn-vulkan
- License: See upstream repositories for the respective MIT/BSD style licenses.

## BasicSR
- Repository: https://github.com/XPixelGroup/BasicSR
- License: Apache License 2.0.

## facexlib
- Repository: https://github.com/xinntao/facexlib
- License: MIT License.

## GFPGAN
- Repository: https://github.com/TencentARC/GFPGAN
- License: Apache License 2.0.

## CodeFormer (optional)
- Repository: https://github.com/sczhou/CodeFormer
- License: S-Lab Non-Commercial License 1.0 (non-commercial use only).
- Status: $cf_status

## Additional dependencies
- PyTorch, torchvision, NCNN binaries, Conda packages, and other libraries remain under their respective upstream licenses. Please consult the downloaded repositories or package metadata for details.

## Notes
- All these components are cloned from their upstream repositories during installation. Please refer to the LICENSE file in each cloned repository for the full legal terms.
