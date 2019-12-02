// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Hidden/SeeThrough"
{
    Properties
    {
    }
    SubShader
    {
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _BumpTex;
		
            struct appdata
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float4 TtoW0 : TEXCOORD1;
				float4 TtoW1 : TEXCOORD2;
				float4 TtoW2 : TEXCOORD3;
            };

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 bump = tex2D(_BumpTex,i.uv);
				bump = fixed4(dot(i.TtoW0.xyz, bump.xyz),
					dot(i.TtoW1.xyz, bump.xyz), dot(i.TtoW2.xyz, bump.xyz), 1);
				bump = bump / 2 + 0.5;
				return normalize(bump);
			}
			ENDCG
		}
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

			sampler2D _NormalTex;
			half4 _NormalTex_TexelSize;
			fixed4 _Color;
			float _Sensitivity;
			float _Threshold;
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv[5] : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				float4 uv = ComputeScreenPos(o.vertex);
				uv = uv / uv.w;
                o.uv[0] = uv.xy;
				o.uv[1] = uv.xy + _NormalTex_TexelSize.xy * half2(1, 1);
				o.uv[2] = uv.xy + _NormalTex_TexelSize.xy * half2(-1, -1);
				o.uv[3] = uv.xy + _NormalTex_TexelSize.xy * half2(-1, 1);
				o.uv[4] = uv.xy + _NormalTex_TexelSize.xy * half2(1, -1);

                return o;
            }
			float CheckSame(half4 center, half4 sample)
			{
				float3 diff = (center.xyz - sample.xyz) * _Sensitivity;
				return length(diff);
			}
			fixed4 frag(v2f i) : SV_Target
			{
				half4 center = 2 * (tex2D(_NormalTex, i.uv[0]) - 0.5);
				half4 sample1 = 2 * (tex2D(_NormalTex, i.uv[1]) - 0.5);
				half4 sample2 = 2 * (tex2D(_NormalTex, i.uv[2]) - 0.5);
				half4 sample3 = 2 * (tex2D(_NormalTex, i.uv[3]) - 0.5);
				half4 sample4 = 2 * (tex2D(_NormalTex, i.uv[4]) - 0.5);
				float diff = CheckSame(center, sample1) + CheckSame(center, sample2) +
					CheckSame(center, sample3) + CheckSame(center, sample4);
				float a = saturate((diff - _Threshold) / _Threshold);
				return _Color * a;
            }
            ENDCG
        }
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _MaskTex;
			sampler2D _SolidColorTex;
			sampler2D _BlurTex;
			fixed4 _Color;
			float _EffWeight;
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 main = tex2D(_MainTex, i.uv);
				fixed4 mask = tex2D(_MaskTex, i.uv);
				fixed4 blur = tex2D(_BlurTex, i.uv);
				fixed4 solid = tex2D(_SolidColorTex, i.uv);
				fixed4 eff = mask + (solid - blur) * _Color;
				eff *= _EffWeight;
				return main + eff;
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
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				return fixed4(1,1,1,1);
			}
			ENDCG
		}	
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			sampler2D _SolidColorTex;
			float4 _SolidColorTex_TexelSize;
			float _BlurSize;
			struct appdata
			{
				float2 uv : TEXCOORD0;
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float2 uv[5] : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				float2 uv = v.uv;
				o.uv[0] = uv;
				o.uv[1] = uv + float2(_SolidColorTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
				o.uv[2] = uv - float2(_SolidColorTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
				o.uv[3] = uv + float2(_SolidColorTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
				o.uv[4] = uv - float2(_SolidColorTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float weight[3] = {0.4026, 0.2442, 0.0545};
				fixed3 sum = tex2D(_SolidColorTex, i.uv[0]).rgb * weight[0];
				for (int it = 1; it < 3; it++)
				{
					sum += tex2D(_SolidColorTex, i.uv[it * 2 - 1]).rgb * weight[it];
					sum += tex2D(_SolidColorTex, i.uv[it * 2]).rgb * weight[it];
				}
				return fixed4(sum, 1);
			}
			ENDCG
		}
				
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			sampler2D _SolidColorTex;
			float4 _SolidColorTex_TexelSize;
			float _BlurSize;
			struct appdata
			{
				float2 uv : TEXCOORD0;
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float2 uv[5] : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				float2 uv = v.uv;
				o.uv[0] = uv;
				o.uv[1] = uv + float2(0.0, _SolidColorTex_TexelSize.y * 1.0) * _BlurSize;
				o.uv[2] = uv - float2(0.0, _SolidColorTex_TexelSize.y * 1.0) * _BlurSize;
				o.uv[3] = uv + float2(0.0, _SolidColorTex_TexelSize.y * 2.0) * _BlurSize;
				o.uv[4] = uv - float2(0.0, _SolidColorTex_TexelSize.y * 2.0) * _BlurSize;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float weight[3] = {0.4026, 0.2442, 0.0545};
				fixed3 sum = tex2D(_SolidColorTex, i.uv[0]).rgb * weight[0];
				for (int it = 1; it < 3; it++)
				{
					sum += tex2D(_SolidColorTex, i.uv[it * 2 - 1]).rgb * weight[it];
					sum += tex2D(_SolidColorTex, i.uv[it * 2]).rgb * weight[it];
				}
				return fixed4(sum, 1);
			}
			ENDCG
		}
	}
}