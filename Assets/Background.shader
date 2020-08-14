Shader "CSShop/PhotoBooth/Background"
{
	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			// Custom post processing effects are written in HLSL blocks,
			// with lots of macros to aid with platform differences.
			// https://github.com/Unity-Technologies/PostProcessing/wiki/Writing-Custom-Effects#shader
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"

			TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
			TEXTURE2D_SAMPLER2D(_BackTex, sampler_BackTex);

			// Data pertaining to _MainTex's dimensions.
			// https://docs.unity3d.com/Manual/SL-PropertiesInPrograms.html
			float4 _MainTex_TexelSize;
			float4 _ColorR;
			float4 _ColorG;
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv     : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				float2 texcoord : TEXCOORD0;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = float4(v.vertex.xy, 0.0, 1.0);
				o.texcoord = TransformTriangleVertexToUV(v.vertex.xy);

				#if UNITY_UV_STARTS_AT_TOP
					o.texcoord = o.texcoord * float2(1.0, -1.0) + float2(0.0, 1.0);
				#endif

				return o;
			}


			float4 frag(v2f i) : SV_Target
			{

				float4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
				float c_a = saturate(c.a);
				float4 b = SAMPLE_TEXTURE2D(_BackTex, sampler_BackTex, i.texcoord);
				c = lerp((_ColorR * b.r) + ( _ColorG * b.g), c, c.a);
				c.a = c_a;
				return c;
			}
			ENDHLSL
		}
	}
}