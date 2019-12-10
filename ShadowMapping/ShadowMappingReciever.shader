Shader "Hidden/ShadowMappingReciever"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			sampler2D _LightDepth;
			float4x4 _LIGHT_MATRIX_MVP;
			sampler2D _CameraDepthTexture;
			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 litpos : TEXCOORD0;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				float4x4 proj;
				proj = mul(_LIGHT_MATRIX_MVP, unity_ObjectToWorld);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.litpos = mul(proj, v.vertex);
				return o;
			}

			sampler2D _MainTex;

			fixed4 frag(v2f i) : SV_Target
			{
				float2 lituv = 0.5 * i.litpos.xy / i.litpos.w + float2(0.5,0.5);
				float z = i.litpos.z;
				float litz = DecodeFloatRGBA(tex2D(_LightDepth, lituv));
				if (litz > z)
					return fixed4(0, 0, 0, 1);
				else
					return fixed4(1, 1, 1, 1);
			}
			ENDCG
		}
    }
}
