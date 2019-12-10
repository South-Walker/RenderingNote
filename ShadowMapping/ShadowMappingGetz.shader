Shader "Hidden/ShadowMappingGetz"
{
    SubShader
    {
		Cull off
		//想要拥有阴影的物体也要拥有对应的标签值
		Tags { "RenderType" = "IsReplace" }
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 depth : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.depth = o.vertex.zw;
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				float depth = i.depth.x;
				float4 col = EncodeFloatRGBA(depth);
				return col;
			}
			ENDCG
		}
    }
}
