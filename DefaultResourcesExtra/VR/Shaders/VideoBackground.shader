// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

/*===============================================================================
Copyright 2017 PTC Inc.

Licensed under the Apache License, Version 2.0 (the "License"); you may not
use this file except in compliance with the License. You may obtain a copy of
the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
===============================================================================*/

Shader "Hidden/VR/VideoBackground" {
    // Used to render the Vuforia Video Background

    Properties {
        _MainTex ("Texture", 2D) = "" {}
    }
    SubShader {
        Tags {"Queue"="geometry-11" "RenderType"="opaque" }
        Pass {
            ZWrite Off Cull Off Lighting Off

            SetTexture [_MainTex] { combine texture }
        }
    }

    Fallback "Legacy Shaders/Diffuse"
}
