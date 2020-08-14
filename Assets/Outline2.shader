Shader "CSShop/PhotoBooth/Outline"
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

			// Data pertaining to _MainTex's dimensions.
			// https://docs.unity3d.com/Manual/SL-PropertiesInPrograms.html
			float4 _MainTex_TexelSize;

			float _Size_Inner;
			float4 _Color_Inner;

			float _Size_Outer;
			float4 _Color_Outer;

			float _Shift_Inner_X;
			float _Shift_Inner_Y;
			float _Shift_Outer_X;
			float _Shift_Outer_Y;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
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

			float Max_Alpha( float2 uv, float s, float shift_x, float shift_y ){
				float alpha_up_left    = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2( -1 * _MainTex_TexelSize.x * (s - shift_x) * 0.707,      _MainTex_TexelSize.y * (s + shift_y) * 0.707)).a;
				float alpha_down_left  = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2( -1 * _MainTex_TexelSize.x * (s - shift_x) * 0.707, -1 * _MainTex_TexelSize.y * (s - shift_y) * 0.707)).a;
				float alpha_up_right   = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2(      _MainTex_TexelSize.x * (s + shift_x) * 0.707,      _MainTex_TexelSize.y * (s + shift_y) * 0.707)).a;
				float alpha_down_right = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2(      _MainTex_TexelSize.x * (s + shift_x) * 0.707, -1 * _MainTex_TexelSize.y * (s - shift_y) * 0.707)).a;

				float alpha_up    = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2( -1 * _MainTex_TexelSize.x * ( 0 - shift_x),  _MainTex_TexelSize.y * (s + shift_y))).a;
				float alpha_down  = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2( -1 * _MainTex_TexelSize.x * ( 0 - shift_x), -1 * _MainTex_TexelSize.y * (s - shift_y))).a;
				float alpha_left  = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2(      _MainTex_TexelSize.x * (s + shift_x) ,      _MainTex_TexelSize.y * (0 + shift_y) )).a;
				float alpha_right = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2(      _MainTex_TexelSize.x * (s + shift_x) , -1 * _MainTex_TexelSize.y * (0 - shift_y) )).a;

				return
				max(
					max( max(alpha_up, alpha_down),	max(alpha_left, alpha_right)),
					max( max(alpha_down_left,alpha_down_right), max(alpha_up_left, alpha_up_right))
				);
			}

			float4 frag(v2f i) : SV_Target
			{

				float4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
				c.a = saturate(c.a);

				float inner_max_a = Max_Alpha( i.texcoord, _Size_Inner, _Shift_Inner_X, _Shift_Inner_Y);
				float outer_max_a = Max_Alpha( i.texcoord, _Size_Outer, _Shift_Outer_X, _Shift_Outer_Y);
				return lerp(lerp(lerp( c, _Color_Outer, saturate( outer_max_a - c.a)), lerp(c, _Color_Inner, saturate(inner_max_a - c.a)), floor(inner_max_a + 0.9)),c,floor(c.a + 0.9) * floor(c.a + 0.1));
			}
			ENDHLSL
		}
	}
}