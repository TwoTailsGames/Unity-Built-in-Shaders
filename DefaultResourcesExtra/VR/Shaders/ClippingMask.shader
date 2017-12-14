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
Shader "Hidden/VR/ClippingMask" {
    // Used to clip objects outside of the Vuforia Video Background

    SubShader {
        // Render the mask after regular geometry and transparent things but
        // but before any other overlays

        Tags {"Queue" = "Overlay-10" }

        Lighting Off

        ZTest Always
        ZWrite On

        // Draw black background into the RGBA channel
        Color (0,0,0,0)
        ColorMask RGBA

        // Do nothing specific in the pass:

        Pass {}
    }
}
