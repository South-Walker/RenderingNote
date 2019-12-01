Shader "Hidden/Scan"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
				float3 interpolatedRay : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };
			sampler2D_float _CameraDepthTexture;
			float4x4 _FrustumCorners;
			float _Radius;
			float _Width;
			float _Fade;
			float3 _CentPos;

			v2f vert(appdata v)
			{
				v2f o;
				half index = v.vertex.z;
				v.vertex.z = 0.1;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv.xy;
				o.interpolatedRay = _FrustumCorners[(int)index].xyz;
				return o;
			}

            fixed4 frag (v2f i) : SV_Target
            {
				fixed depth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, UnityStereoTransformScreenSpaceTex(i.uv)));

				fixed4 worldPos = fixed4(depth * i.interpolatedRay, 1);

				worldPos.xyz += _WorldSpaceCameraPos;

				fixed dis = length(_CentPos.xyz - worldPos.xyz);
				//fixed pre = saturate(dis - _Radius + abs(dis - _Radius));
				//pre /= 2;
				fixed a = 1 - saturate((abs(dis - _Radius) - _Width) / _Fade);
				return fixed4(a, a, a, a);
            }
            ENDCG
        }
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			sampler2D _MainTex;
			sampler2D _MaskTex;
			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				fixed4 mask = tex2D(_MaskTex, i.uv) * 0.75;
				fixed4 maskcol = fixed4(0.75, 0.75, 0, 1);
				col += mask * maskcol;
				return col;
			}
				ENDCG
		}
	}
}
