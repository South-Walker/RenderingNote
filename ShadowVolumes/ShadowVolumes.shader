Shader "Hidden/ShadowVolumes"
{
	Properties
	{
		_Extrusion("Extrusion",Range(0,100)) = 30
		_LightPosition("LightPosition",Vector) = (0,0,0,0)
	}
		SubShader
	{
		ColorMask A
		CGINCLUDE
		#include "UnityCG.cginc"
		float4 _LightPosition;
		float _Extrusion;
		struct a2v
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
		};
		float4 vertextrusion(a2v v) : POSITION
		{
			//这里特意把坐标当作行矢量，右乘了IT_MV矩阵
			//等效于左乘I_MV矩阵
			float4 objLightPos = mul(_LightPosition,UNITY_MATRIX_IT_MV);
			//这个w是标识是点光源(1)还是平行光源(0)
			float3 toLight = normalize(objLightPos.xyz - v.vertex.xyz * objLightPos.w);
			float backFactor = dot(toLight, v.normal);
			float extrude = (backFactor <= 0.0001) ? 1 : 0;
			v.vertex.xyz -= toLight * (extrude * _Extrusion);
			return UnityObjectToClipPos(v.vertex);
		}
		ENDCG
		Pass
		{
			Cull Back
			ZWrite Off
			CGPROGRAM
			#pragma vertex vertextrusion
			#pragma fragment frag
			fixed4 frag(float4 i : POSITION) : SV_Target
			{
				return fixed4(1,1,1,0);
			}
			ENDCG
		}
        Pass
        {
			Cull Front
			ZWrite Off
            CGPROGRAM
            #pragma vertex vertextrusion
            #pragma fragment frag
			fixed4 frag(float4 i : POSITION) : SV_Target
			{
				return fixed4(1,1,1,1);
            }
            ENDCG
        }
		Pass
		{
			ColorMask ARGB
			Cull Back
			ZWrite Off
			Blend OneMinusDstAlpha DstAlpha, One Zero 
			CGPROGRAM
			#pragma vertex vertextrusion
			#pragma fragment frag

			#include "UnityCG.cginc"


			fixed4 frag(float4 i : POSITION) : SV_Target
			{
				return fixed4(0.1,0.1,0.1,1);
			}
			ENDCG
		}

		Pass
		{
			ColorMask ARGB
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			float4 vert(appdata_base v) : POSITION
			{
				return UnityObjectToClipPos(v.vertex);
			}
			float4 frag(float4 i : POSITION) : COLOR
			{
				return float4(0.5,0.5,0.5,0.5);
			}
			ENDCG
		}
    }
}
