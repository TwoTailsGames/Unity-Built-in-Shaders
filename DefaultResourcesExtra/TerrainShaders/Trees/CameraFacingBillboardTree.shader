// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/TerrainEngine/CameraFacingBillboardTree" {
    Properties{
        _MainTex("Base (RGB) Alpha (A)", 2D) = "white" {}
    }

        SubShader{
            Tags {
                "IgnoreProjector" = "True" "RenderType" = "TreeBillboard" }

            Pass {
                ColorMask rgb
                ZWrite On Cull Off
                AlphaToMask On

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma multi_compile_fog
                #include "UnityCG.cginc"
                #include "UnityBuiltin3xTreeLibrary.cginc"

                struct v2f {
                    float4 pos : SV_POSITION;
                    fixed4 color : COLOR0;
                    float3 uv : TEXCOORD0;
                    UNITY_FOG_COORDS(1)
                    UNITY_VERTEX_OUTPUT_STEREO
                    float4 screenPos : TEXCOORD2;

                };



        void CameraFacingBillboardVert(inout float4 pos, float2 offset, float offsetz)
        {
            float3 vertViewVector = pos.xyz - _TreeBillboardCameraPos.xyz;
            float treeDistanceSqr = dot(vertViewVector, vertViewVector);
            float distance = sqrt(treeDistanceSqr);
            if (treeDistanceSqr > _TreeBillboardDistances.x)
                offset.xy = offsetz = 0.0;
            // Create LookAt matrix
            float3 up = float3(0, 1, 0);
            float3 zaxis = vertViewVector / distance; // distance won't be 0 since billboard would already be clipped by near plane
            float3 xaxis = normalize(cross(up, zaxis)); // direct top down view of billboard won't be visible due its orientation about yaxis
            float vertexCameraDistance = distance - _TreeBillboardDistances.z;
            float fadeAmount = saturate(vertexCameraDistance / _TreeBillboardDistances.w);
            pos.w = fadeAmount;
            if (vertexCameraDistance > _TreeBillboardDistances.w)
                pos.w = 1.0;

            // positioning of billboard vertices horizontally
            pos.xyz += xaxis * offset.x;
            float radius = offset.y;
            // positioning of billboard vertices veritally
            pos.xyz += up * radius;
        }

                v2f vert(appdata_tree_billboard v) {
                    v2f o;
                    UNITY_SETUP_INSTANCE_ID(v);
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                    CameraFacingBillboardVert(v.vertex, v.texcoord1.xy, v.texcoord.y);
                    o.uv.z = v.vertex.w;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.uv.x = v.texcoord.x;
                    o.uv.y = v.texcoord.y > 0;

                    o.color = v.color;
                    o.screenPos = ComputeScreenPos(o.pos);
                    UNITY_TRANSFER_FOG(o,o.pos);
                    return o;
                }

                sampler2D _MainTex;
                fixed4 frag(v2f input) : SV_Target
                {
                    fixed4 col = tex2D(_MainTex, input.uv.xy);
                    col.rgb *= input.color.rgb;
                    float coverage = ComputeAlphaCoverage(input.screenPos, input.uv.z);
                    col.a *= coverage;
                    clip(col.a - _TreeBillboardCameraFront.w);
                    UNITY_APPLY_FOG(input.fogCoord, col);
                    return col;
                }
                ENDCG
            }
    }

        Fallback Off
}
