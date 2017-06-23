#ifndef UNITY_SHADER_VARIABLES_FUNCTIONS_INCLUDED
#define UNITY_SHADER_VARIABLES_FUNCTIONS_INCLUDED

float4x4 GetWorldToViewMatrix()
{
    return UNITY_MATRIX_V;
}

float4x4 GetObjectToWorldMatrix()
{
    return UNITY_MATRIX_M;
}

float4x4 GetWorldToObjectMatrix()
{
    return UNITY_MATRIX_I_M;
}

// Transform to homogenous clip space
float4x4 GetWorldToHClipMatrix()
{
    return UNITY_MATRIX_VP;
}

float GetOddNegativeScale()
{
    return unity_WorldTransformParams.w;
}

float3 TransformWorldToView(float3 positionWS)
{
    return mul(GetWorldToViewMatrix(), float4(positionWS, 1.0)).xyz;
}

float3 TransformObjectToWorld(float3 positionOS)
{
    return mul(GetObjectToWorldMatrix(), float4(positionOS, 1.0)).xyz;
}

float3 TransformWorldToObject(float3 positionWS)
{
    return mul(GetWorldToObjectMatrix(), float4(positionWS, 1.0)).xyz;
}

float3 TransformObjectToWorldDir(float3 dirOS)
{
    // Normalize to support uniform scaling
    return normalize(mul((float3x3)GetObjectToWorldMatrix(), dirOS));
}

float3 TransformWorldToObjectDir(float3 dirWS)
{
    // Normalize to support uniform scaling
    return normalize(mul((float3x3)GetWorldToObjectMatrix(), dirWS));
}

// Transforms normal from object to world space
float3 TransformObjectToWorldNormal(float3 normalOS)
{
#ifdef UNITY_ASSUME_UNIFORM_SCALING
    return UnityObjectToWorldDir(normalOS);
#else
    // Normal need to be multiply by inverse transpose
    // mul(IT_M, norm) => mul(norm, I_M) => {dot(norm, I_M.col0), dot(norm, I_M.col1), dot(norm, I_M.col2)}
    return normalize(mul(normalOS, (float3x3)GetWorldToObjectMatrix()));
#endif
}

// Tranforms position from world space to homogenous space
float4 TransformWorldToHClip(float3 positionWS)
{
    return mul(GetWorldToHClipMatrix(), float4(positionWS, 1.0));
}

float3 GetCurrentCameraPosition()
{
#if defined(SHADERPASS) && (SHADERPASS != SHADERPASS_SHADOWS)
    return _WorldSpaceCameraPos;
#else
    // TEMP: this is rather expensive. Then again, we need '_WorldSpaceCameraPos'
    // to represent the position of the primary (scene view) camera in order to
    // have identical tessellation levels for both the scene view and shadow views.
    // Otherwise, depth comparisons become meaningless!
    float4x4 trViewMat = transpose(GetWorldToViewMatrix());
    float3   rotCamPos = trViewMat[3].xyz;
   return mul((float3x3)trViewMat, -rotCamPos);
#endif
}

// Returns the forward direction of the current camera in the world space.
float3 GetCameraForwardDir()
{
    float4x4 viewMat = GetWorldToViewMatrix();
    return -viewMat[2].xyz;
}

// Returns 'true' if the current camera performs a perspective projection.
bool IsPerspectiveCamera()
{
#if defined(SHADERPASS) && (SHADERPASS != SHADERPASS_SHADOWS)
    return (unity_OrthoParams.w == 0);
#else
    // TODO: set 'unity_OrthoParams' during the shadow pass.
    return (GetWorldToHClipMatrix()[3].x != 0 ||
            GetWorldToHClipMatrix()[3].y != 0 ||
            GetWorldToHClipMatrix()[3].z != 0 ||
            GetWorldToHClipMatrix()[3].w != 1);
#endif
}

// Computes the world space view direction (pointing towards the camera).
float3 GetWorldSpaceNormalizeViewDir(float3 positionWS)
{
    if (IsPerspectiveCamera())
    {
        // Perspective
        float3 V = GetCurrentCameraPosition() - positionWS;
        return normalize(V);
    }
    else
    {
        // Orthographic
        return -GetCameraForwardDir();
    }
}

float3x3 CreateWorldToTangent(float3 normal, float3 tangent, float flipSign)
{
    // For odd-negative scale transforms we need to flip the sign
    float sgn = flipSign * GetOddNegativeScale();
    float3 bitangent = cross(normal, tangent) * sgn;

    return float3x3(tangent, bitangent, normal);
}

float3 TransformTangentToWorld(float3 dirTS, float3x3 worldToTangent)
{
    // Use transpose transformation to go from tangent to world as the matrix is orthogonal
    return mul(dirTS, worldToTangent);
}

float3 TransformWorldToTangent(float3 dirWS, float3x3 worldToTangent)
{
    return mul(worldToTangent, dirWS);
}

float3 TransformTangentToObject(float3 dirTS, float3x3 worldToTangent)
{
    // Use transpose transformation to go from tangent to world as the matrix is orthogonal
    float3 normalWS = mul(dirTS, worldToTangent);
    return mul((float3x3)GetWorldToObjectMatrix(), normalWS);
}

float3 TransformObjectToTangent(float3 dirOS, float3x3 worldToTangent)
{
    return mul(worldToTangent, TransformObjectToWorldDir(dirOS));
}

#endif // UNITY_SHADER_VARIABLES_FUNCTIONS_INCLUDED
