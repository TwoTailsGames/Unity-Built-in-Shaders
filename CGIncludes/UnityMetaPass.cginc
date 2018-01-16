// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#ifndef UNITY_META_PASS_INCLUDED
#define UNITY_META_PASS_INCLUDED


CBUFFER_START(UnityMetaPass)
    // x = use uv1 as raster position
    // y = use uv2 as raster position
    bool4 unity_MetaVertexControl;

    // x = return albedo
    // y = return normal
    bool4 unity_MetaFragmentControl;

    // Control which VisualizationMode we will
    // display in the editor
    int unity_VisualizationMode;
CBUFFER_END


struct UnityMetaInput
{
    half3 Albedo;
    half3 Emission;
    half3 SpecularColor;
};

#if defined(EDITOR_VISUALIZATION)

//Visualization defines
// Should be kept in sync with the EditorVisualizationMode enum in EditorCameraDrawing.cpp
#define PBR_VALIDATION_ALBEDO 0
#define PBR_VALIDATION_METALSPECULAR 1

uniform int _CheckPureMetal = 0;// flag to check only full metal, not partial metal, known because it has metallic features and pure black albedo
uniform int _CheckAlbedo = 0; // if 0, pass through untouched color
uniform half4 _AlbedoCompareColor = half4(0.0, 0.0, 0.0, 0.0);
uniform half _AlbedoMinLuminance = 0.0;
uniform half _AlbedoMaxLuminance = 1.0;
uniform half _AlbedoHueTolerance = 0.1;
uniform half _AlbedoSaturationTolerance = 0.1;

uniform half4 unity_MaterialValidateLowColor = half4(1.0f, 0.0f, 0.0f, 0.0f);
uniform half4 unity_MaterialValidateHighColor = half4(0.0f, 0.0f, 1.0f, 0.0f);
uniform half4 unity_MaterialValidatePureMetalColor = half4(1.0f, 1.0f, 0.0f, 0.0f);

// Define bounds value in linear RGB for fresnel0 values
static const float dieletricMin = 0.02;
static const float dieletricMax = 0.07;
static const float gemsMin      = 0.07;
static const float gemsMax      = 0.22;
static const float conductorMin = 0.45;
static const float conductorMax = 1.00;
static const float albedoMin    = 0.012;
static const float albedoMax    = 0.9;

half3 UnityMeta_RGBToHSVHelper(float offset, half dominantColor, half colorone, half colortwo)
{
    half H, S, V;
    V = dominantColor;

    if (V != 0.0)
    {
        half small = 0.0;
        if (colorone > colortwo)
            small = colortwo;
        else
            small = colorone;

        half diff = V - small;

        if (diff != 0)
        {
            S = diff / V;
            H = offset + ((colorone - colortwo)/diff);
        }
        else
        {
            S = 0;
            H = offset + (colorone - colortwo);
        }

        H /= 6.0;

        if (H < 6.0)
        {
            H += 1.0;
        }
    }
    else
    {
        S = 0;
        H = 0;
    }
    return half3(H, S, V);
}

half3 UnityMeta_RGBToHSV(half3 rgbColor)
{
    // when blue is highest valued
    if((rgbColor.b > rgbColor.g) && (rgbColor.b > rgbColor.r))
        return UnityMeta_RGBToHSVHelper(4.0, rgbColor.b, rgbColor.r, rgbColor.g);
    //when green is highest valued
    else if(rgbColor.g > rgbColor.r)
        return UnityMeta_RGBToHSVHelper(2.0, rgbColor.g, rgbColor.b, rgbColor.r);
    //when red is highest valued
    else
        return UnityMeta_RGBToHSVHelper(0.0, rgbColor.r, rgbColor.g, rgbColor.b);
}



// Pass 0 - Albedo
half4 UnityMeta_pbrAlbedo(UnityMetaInput IN)
{
    half3 SpecularColor = IN.SpecularColor;
    half3 baseColor = IN.Albedo;

    if (IsGammaSpace())
    {
        baseColor = half3( GammaToLinearSpaceExact(baseColor.x), GammaToLinearSpaceExact(baseColor.y), GammaToLinearSpaceExact(baseColor.z) ); //GammaToLinearSpace(baseColor);
        SpecularColor = GammaToLinearSpace(SpecularColor);
    }

    half3 unTouched = LinearRgbToLuminance(baseColor).xxx; // if no errors, leave color as it was in render

    bool isMetal = dot(SpecularColor, float3(0.3333,0.3333,0.3333)) >= conductorMin;
    // When checking full range we do not take the luminance but the mean because often in game blue color are highlight as too low whereas this is what we are looking for.
    half value = _CheckAlbedo ? LinearRgbToLuminance(baseColor) : dot(baseColor, half3(0.3333, 0.3333, 0.3333));

     // Check if we are pure metal with black albedo
    if (_CheckPureMetal && isMetal && value != 0.0)
        return unity_MaterialValidatePureMetalColor;

    if (_CheckAlbedo == 0)
    {
        // If we have a metallic object, don't complain about low albedo
        if (!isMetal && value < albedoMin)
        {
            return unity_MaterialValidateLowColor;
        }
        else if (value > albedoMax)
        {
            return unity_MaterialValidateHighColor;
        }
        else
        {
            return half4(unTouched, 0);
        }
    }
    else
    {
        if (_AlbedoMinLuminance > value)
        {
             return unity_MaterialValidateLowColor;
        }
        else if (_AlbedoMaxLuminance < value)
        {
             return unity_MaterialValidateHighColor;
        }
        else
        {
            half3 hsv = UnityMeta_RGBToHSV(IN.Albedo);
            half hue = hsv.r;
            half sat = hsv.g;

            half3 compHSV = UnityMeta_RGBToHSV(_AlbedoCompareColor.rgb);
            half compHue = compHSV.r;
            half compSat = compHSV.g;

            if ((compSat - _AlbedoSaturationTolerance > sat) || ((compHue - _AlbedoHueTolerance > hue) && (compHue - _AlbedoHueTolerance + 1.0 > hue)))
            {
                return unity_MaterialValidateLowColor;
            }
            else if ((sat > compSat + _AlbedoSaturationTolerance) || ((hue > compHue + _AlbedoHueTolerance) && (hue > compHue + _AlbedoHueTolerance - 1.0)))
            {
                return unity_MaterialValidateHighColor;
            }
            else
            {
                return half4(unTouched, 0);
            }
        }
    }

    return half4(1.0, 0, 0, 1);
}

// Pass 1 - Metal Specular
half4 UnityMeta_pbrMetalspec(UnityMetaInput IN)
{
    half3 SpecularColor = IN.SpecularColor;
    half4 baseColor = half4(IN.Albedo, 0);

    if (IsGammaSpace())
    {
        baseColor.xyz = GammaToLinearSpace(baseColor.xyz);
        SpecularColor = GammaToLinearSpace(SpecularColor);
    }

    // Take the mean of three channel, works ok.
    half value = dot(SpecularColor, half3(0.3333,0.3333,0.3333));
    bool isMetal = value >= conductorMin;

    half4 outColor = half4(LinearRgbToLuminance(baseColor.xyz).xxx, 1.0f);

    if (value < conductorMin)
    {
         outColor = unity_MaterialValidateLowColor;
    }
    else if (value > conductorMax)
    {
        outColor = unity_MaterialValidateHighColor;
    }
    else if (isMetal)
    {
         // If we are here we supposed the users want to have a metal, so check if we have a pure metal (black albedo) or not
        // if it is not a pure metal, highlight it
        if (_CheckPureMetal)
            outColor = dot(baseColor.xyz, half3(1,1,1)) == 0 ? outColor : unity_MaterialValidatePureMetalColor;
    }

    return outColor;
}

#endif

float4 UnityMetaVertexPosition (float4 vertex, float2 uv1, float2 uv2, float4 lightmapST, float4 dynlightmapST)
{
    if (unity_MetaVertexControl.x)
    {
        vertex.xy = uv1 * lightmapST.xy + lightmapST.zw;
        // OpenGL right now needs to actually use incoming vertex position,
        // so use it in a very dummy way
        vertex.z = vertex.z > 0 ? 1.0e-4f : 0.0f;
    }
    if (unity_MetaVertexControl.y)
    {
        vertex.xy = uv2 * dynlightmapST.xy + dynlightmapST.zw;
        // OpenGL right now needs to actually use incoming vertex position,
        // so use it in a very dummy way
        vertex.z = vertex.z > 0 ? 1.0e-4f : 0.0f;
    }
    return UnityObjectToClipPos(vertex);
}

float unity_OneOverOutputBoost;
float unity_MaxOutputValue;
float unity_UseLinearSpace;

half4 UnityMetaFragment (UnityMetaInput IN)
{
    half4 res = 0;
    #if !defined(EDITOR_VISUALIZATION)
    if (unity_MetaFragmentControl.x)
    {
        res = half4(IN.Albedo,1);

        // d3d9 shader compiler doesn't like NaNs and infinity.
        unity_OneOverOutputBoost = saturate(unity_OneOverOutputBoost);

        // Apply Albedo Boost from LightmapSettings.
        res.rgb = clamp(pow(res.rgb, unity_OneOverOutputBoost), 0, unity_MaxOutputValue);
    }
    if (unity_MetaFragmentControl.y)
    {
        half3 emission;
        if (unity_UseLinearSpace)
            emission = IN.Emission;
        else
            emission = GammaToLinearSpace(IN.Emission);

        res = half4(emission, 1.0);
    }
    #else
    if ( unity_VisualizationMode == PBR_VALIDATION_ALBEDO )
    {
        res = UnityMeta_pbrAlbedo(IN);
    }
    else if (unity_VisualizationMode == PBR_VALIDATION_METALSPECULAR)
    {
        res = UnityMeta_pbrMetalspec(IN);
    }
    #endif
    return res;
}

#endif // UNITY_META_PASS_INCLUDED
