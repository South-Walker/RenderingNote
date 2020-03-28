Shader "Hidden/Burning"
{
    Properties
    {
        _Book ("Texture", 2D) = "white" {}
		_BurnedBook ("Texture", 2D) = "white" {}
		_Noise ("Texture", 2D) = "white" {}
		_SparkColor ("Spark", Color) = (1,1,1,1)
		_BurningColor ("Burning", Color) = (1,1,1,1)
		_Degree("Degree", Float) = 1
		_BurningRate("BurningRate", Float) = 0.1
		_BurningSteepness ("Steepness", Float) = 0.1
		_BurningOffset ("BurningOffset", Float) = 0.5
		_AshRate ("AshRate", Float) = 0.5
		_VertexOffset ("VertexOffset", Float) = 0.1
    }
    SubShader
    {
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
				float4 noiseuv : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _Book;
			sampler2D _BurnedBook;
			sampler2D _Noise;
			float4 _Noise_ST;
			float4 _SparkColor;
			float4 _BurningColor;
			float _Degree;
			float _BurningRate;
			float _BurningSteepness;
			float _BurningOffset;
			float _AshRate;
			float _VertexOffset;

			float GetDistance(float2 uv)
			{
				//简单由左至右
				//return uv.x;
				float x = uv.x - 0.5;
				float y = uv.y - 0.5;
				return x * x * 3 + y * y * 4;
			}

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = v.uv;
				o.noiseuv = TRANSFORM_TEX(v.uv, _Noise).xyxy * half4(1, 1, 1.3, 1.3) + 1.0 * _Time.x;

				float distance = GetDistance(v.uv);

				float noise = tex2Dlod(_Noise, o.noiseuv);
				float vertoffset = (noise*noise)* smoothstep(0, 1, (1 - distance)*_Degree) * _VertexOffset;

				o.vertex = UnityObjectToClipPos(v.vertex + float4(0, vertoffset, 0, 0));
                return o;
            }


			fixed4 frag(v2f i) : SV_Target
			{
				fixed noise = (tex2D(_Noise , i.noiseuv.xy) + tex2D(_Noise, i.noiseuv.zw)) * 0.5;
                fixed4 colash = tex2D(_BurnedBook, i.uv);
				fixed4 col = tex2D(_Book, i.uv);

				float distance = GetDistance(i.uv);
				//noise-0.5是随机扰动， 
				//_EmberRate * _Degree * (1 + _BurningRate)是Ember所占的部分
				//*_Degree + 0.05保证在_Degree小到Burning区域不明显时，不会因为noise扰动使得裁剪提前
				clip((distance + (noise - 0.5) - _AshRate * _Degree * (1 + _BurningRate))* _Degree + 0.05);

				//噪音图有点太暗了
				fixed4 spark = (smoothstep(0.85, 1, noise * 1.3)) * _SparkColor;


				//计算混合因子,利用适当缩小的noise控制边缘渐变
				//blendvalue为distance + noise * _BurningRate在Buring区域的位置，截断到0-1
				half blendvalue = smoothstep(_Degree * (1 - _BurningRate), _Degree * (1 + _BurningRate), distance + noise * _BurningRate);
				col.rgb = lerp(colash + spark, col, blendvalue);

				//利用blendvalue在完好边和灰烬边分别为1与0
				//fixed4 burningcol = blendvalue * (1 - blendvalue) * _BurningColor;
				//用上式计算会导致过渡区全为火焰遮罩，缺少灰烬的渐变
				//代替的，使用1-((x-a)^2)/b,并用blendvalue * (1 - blendvalue)约束零点位置，
				//由于，a,b过小时火焰过暗，乘10作为系数
				fixed3 burningcol = blendvalue * (1 - blendvalue) * 
					max(0, 1 - (blendvalue - _BurningOffset) * (blendvalue - _BurningOffset) / _BurningSteepness)
					* _BurningColor.rgb * 10;

				col.rgb += burningcol;
                return col;
            }
            ENDCG
        }
    }
}
