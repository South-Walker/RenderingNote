Shader "Unlit/Tessellation"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_MaskTex("Mask", 2D) = "white" {}
		_Wind("Wind", vector) = (0,0,0,0)
		_Blend("Blend", float) = 0
		_Swing("Swing", float) = 0
		//相位差
		_Distance("Distance", float) = 0
		_Speed("Speed", float) = 0
	}
	SubShader
	{
		Tags{ "Queue" = "AlphaTest" "RenderType" = "TransparentCutout" "IgnoreProjector" = "True" }
		Pass
		{

			Cull OFF
			Tags{ "LightMode" = "ForwardBase" }
			AlphaToMask On
			CGPROGRAM
			//最终线段数
			#define LOD 21
			//最终节点数
			#define LODANDONE LOD+1
			#define INPUTSIZE 4
			#pragma vertex vert
			#pragma hull hs
			#pragma domain ds
			#pragma geometry geom 
			#pragma fragment frag
			#pragma require geometry
			#pragma require tessellation
			#include "UnityCG.cginc"
			float _Width;
			float4 _Wind;
			struct a2v
			{
				float4 vertex : POSITION;
				//传的不是面的法线
				float3 EW : NORMAL;
			};
			struct v2t
			{
				float4 vertex : INTERNALTESSPOS;
				float3 EW : TEXCOORD0;
			};
			struct h2d
			{
				float4 vertex : INTERNALTESSPOS;
				float3 EW : TEXCOORD0;
			};
			struct hc2d
			{
				float edge[2] : SV_TessFactor;
			};
			struct d2g
			{
				float4 vertex : TEXCOORD0;
				float3 edge : TEXCOORD1;
				float v : TEXCOORD2;
			};
			struct g2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2t vert(a2v v)
			{
				v2t o;
				o.vertex = v.vertex;
				o.EW = v.EW;
				return o;
			}

			hc2d hsconst(InputPatch<v2t, INPUTSIZE> v)
			{
				hc2d o;
				o.edge[0] = 1;
				o.edge[1] = LOD;
				return o;
			}
			float4 RorateAroundLine(float3 rline, float3 lineorigin, float4 vertex, float agree)
			{
				float4 ans;
				float sinx = sin(agree);
				float cosx = cos(agree);
				float3 l = normalize(rline);
				float u = l.x;
				float v = l.y;
				float w = l.z;
				vertex.xyz -= lineorigin.xyz * vertex.w;
				float4 r0 = float4(
					u * u + (1 - u * u) * cosx,
					u * v * (1 - cosx) - w * sinx,
					u * w * (1 - cosx) + v * sinx,
					0);
				ans.x = dot(r0, vertex);
				float4 r1 = float4(
					u * v * (1 - cosx) + w * sinx,
					v * v + (1 - v * v) * cosx,
					v * w * (1 - cosx) - u * sinx,
					0);
				ans.y = dot(r1, vertex);
				float4 r2 = float4(
					u * w * (1 - cosx) - v * sinx,
					v * w * (1 - cosx) + u * sinx,
					w * w + (1 - w * w) * cosx,
					0);
				ans.z = dot(r2, vertex);
				float4 r3 = float4(0, 0, 0, 1);
				ans.w = dot(r3, vertex);
				ans.xyz += lineorigin.xyz * vertex.w;
				return ans;
			}
			float _Blend;
			float _Swing;
			float _Distance;
			float _Speed;
			[UNITY_domain("isoline")]
			[UNITY_partitioning("integer")]
			[UNITY_outputtopology("line")]
			[UNITY_patchconstantfunc("hsconst")]
			[UNITY_outputcontrolpoints(LODANDONE)]
			h2d hs(InputPatch<v2t, INPUTSIZE> v, uint id : SV_OutputControlPointID)
			{
				h2d o = v[id%INPUTSIZE];
				if (id < INPUTSIZE)
				{
					float3 windatv0 = (
						sin(dot(v[0].vertex.xyz, _Wind.xyz) / _Distance + _Time.y * _Speed)
						+ 1.0f) / 2.0f * _Wind.xyz;
					//Blend
					float3 tangent = v[1].vertex - v[0].vertex;
					float3 normal = normalize(cross(tangent, v[0].EW));
					float Fb = dot(windatv0, normal);
					float b = Fb / _Blend;
					//blend角x满足11*x/6>1.57会让尖端低于根
					b = min(0.85f, b);
					b = max(-0.85f, b);
					for (uint i = 0; i < id; i++)
					{
						o.vertex = RorateAroundLine(v[i].EW, v[i].vertex, o.vertex, b);
						b *= (float)(i + 1) / (float)(i + 2);
					}
					//Swing
					float3 up = float3(0, 1, 0);
					float Fs = dot(windatv0, v[0].EW);
					float s = Fs / _Swing;
					//s = min(0.85f, s);
					//s = max(-0.85f, s);
					for (uint i = 0; i <= id; i++)
					{
						o.vertex = RorateAroundLine(up, v[0].vertex, o.vertex, s);
						o.EW = RorateAroundLine(up, v[0].vertex, float4(o.EW, 0), s).xyz;
						s *= (float)(i + 1) / (float)(i + 2);
					}
				}
				return o;
			}

			[UNITY_domain("isoline")]
			d2g ds(hc2d tessFactors, const OutputPatch<h2d, LODANDONE> vi, float2 bary : SV_DomainLocation)
			{
				uint count = LOD;
				uint now = round(count * bary.x);


				d2g o;
				o.v = bary.x;

				float t = bary.x;
				o.vertex = (1 - t) * (1 - t) * (1 - t) * vi[0].vertex
					+ 3 * (1 - t) * (1 - t) * t * vi[1].vertex
					+ 3 * (1 - t) * t * t * vi[2].vertex
					+ t * t * t * vi[3].vertex;
				o.vertex.w = 1;
				o.edge = vi[0].EW;
				
				return o;
			}

			[maxvertexcount(20)]
			void geom(line d2g IN[2], inout TriangleStream<g2f> outStream)
			{
				g2f v[4];
				for (uint id = 0; id < 4; id++)
				{
					uint iid = id / 2;
					v[id].vertex = IN[iid].vertex;

					if (fmod(id, 2) == 0)
					{
						v[id].vertex.xyz -= IN[iid].edge;
						v[id].uv = float2(0, IN[iid].v);
					}
					else
					{
						v[id].vertex.xyz += IN[iid].edge;
						v[id].uv = float2(1, IN[iid].v);
					}
					v[id].vertex = UnityObjectToClipPos(v[id].vertex);
				}
				for (uint k = 0; k < 2; k++)
				{
					outStream.Append(v[k]);
					outStream.Append(v[k + 1]);
					outStream.Append(v[k + 2]);
					outStream.RestartStrip();
					outStream.Append(v[k + 2]);
					outStream.Append(v[k + 1]);
					outStream.Append(v[k]);
					outStream.RestartStrip();
				}
			}

			sampler2D _MainTex;
			sampler2D _MaskTex;
			fixed4 frag(g2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex,i.uv);
				col.a = tex2D(_MaskTex, i.uv).x;
				return col;
			}
			ENDCG
		}
	}
}