// Upgrade NOTE: upgraded instancing buffer 'InstanceProperties' to new syntax.

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "CSShop/CSShop_VertexLit_Volume"
{
	Properties {
		_MainTex ("Texture", 2D) = "white" {}

		_AmbientColor("Volume Ambient Color", Color) = (0,0,0,0)
		_LightColor("Volume Directional Light Color", Color) = (0,0,0,0)
		_LightDirection("Volume Light Direction", Vector) = (1,1,1,1)

		_AlphaChanelValue("Write alpha value", float) = 1

		_Recolor("_Recolor", Color) = (1,1,1,1)

		_AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1)
		_SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1)
		// Controls the size of the specular reflection.
		_Glossiness("Glossiness", Float) = 32
		_RimColor("Rim Color", Color) = (1,1,1,1)
		_RimAmount("Rim Amount", Range(0, 1)) = 0.716
		// Control how smoothly the rim blends when approaching unlit
		// parts of the surface.
		_RimThreshold("Rim Threshold", Range(0, 1)) = 0.1

		_HalftoneTex("Halftone pattern", 2D) = "black" {}
		_HalftoneColor("Halftone Color", Color) = (1,1,1,1)
		_Halftone_Scale("Halftone scale", Float) = 1.0
		_AmbientColor_Static("Static Ambient Color", Color) = (0,0,0,0)
		_LightColor_Static("Static Light Color", Color) = (0,0,0,0)
		_LightDirection_Static("Static Indoor Color Direction", Vector) = (1,1,1,1)

		[Toggle(USE_VOLUME_LIGHT)] _UseVolumeLight("USE_VOLUME_LIGHT ?", Float) = 0
		[Toggle(RECOLOR_SUPPORT)] _RecolorSupport("RECOLOR_SUPPORT ?", Float) = 0

		[Header(Use this value to make things brighter)] _WhiteIntencity("Brightness", Range(-1, 1)) = 0

		[Header(Shadow darkness)] _ShadowDarknessWeight("Shadows Darkness", Range(0,1)) = 0.5

		_ShadowIntensity("Shadow Intensity", Color) = (0.5, 0.5, 0.5, 1.0)
		//_Outline_Color_Mask("_Outline_Color_Mask", Int) = 14

		_UvShift("X UV shift", Float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry" "IgnoreProjector"="True" }

		LOD 100

		Pass
		{
			Tags { "LightMode"="ForwardBase" }

			//ColorMask [_Outline_Color_Mask]

			Cull Back

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma enable_d3d11_debug_symbols

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog

			#pragma multi_compile_local __ USE_VOLUME_LIGHT
			#pragma multi_compile_local __ RECOLOR_SUPPORT

			#pragma multi_compile_instancing


			#include "UnityCG.cginc"
			#include "UnityStandardUtils.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			struct appdata {
				float4 vertex : POSITION;
				float4 uv     : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				half2 uv : TEXCOORD0;
				float3 worldNormal : NORMAL;
				fixed3 lmap : TEXCOORD1;
				float3 viewDir : TEXCOORD2;
				// SHADOW_COORDS(2)
			};

			sampler2D _MainTex;
			half4 _MainTex_ST;
			sampler2D _HalftoneTex;
			half4 _HalftoneTex_ST;
			float4 _HalftoneColor;
			// sampler2D _RimTex;
 			float _Halftone_Scale;

			half _Glossiness;
			half _WhiteIntencity;
			half _ShadowDarknessWeight;
			half _AlphaChanelValue;

			float4 _AmbientColor_Static;
			float4 _LightColor_Static;
			float4 _LightDirection_Static;
			half _Light_Intensity_Static;

			///////
			float4 _SpecularColor;

			float4 _RimColor;
			float _RimAmount;
			float _RimThreshold;
			float4 _ShadowIntensity;
			//////

			UNITY_INSTANCING_BUFFER_START(InstanceProperties)
			UNITY_DEFINE_INSTANCED_PROP(half, _UvShift)

			#if defined(USE_VOLUME_LIGHT)
				UNITY_DEFINE_INSTANCED_PROP(float4, _LightColor)
				UNITY_DEFINE_INSTANCED_PROP(float4, _LightDirection)
				UNITY_DEFINE_INSTANCED_PROP(float4, _AmbientColor)
			#endif

			#if defined(RECOLOR_SUPPORT)
				UNITY_DEFINE_INSTANCED_PROP(float,	_Recolor_Work)
				UNITY_DEFINE_INSTANCED_PROP(float4, _Recolor)
				UNITY_DEFINE_INSTANCED_PROP(float, _Recolor_Coef1)
				UNITY_DEFINE_INSTANCED_PROP(float, _Recolor_Coef2)
			#endif

			UNITY_INSTANCING_BUFFER_END(InstanceProperties)

			v2f vert (appdata_full v)
			{
				UNITY_SETUP_INSTANCE_ID(v);
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
				o.uv.x += UNITY_ACCESS_INSTANCED_PROP(InstanceProperties, _UvShift);
				o.viewDir = WorldSpaceViewDir(v.vertex);

				float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
				float3 normalWorld = UnityObjectToWorldNormal(v.normal);

				o.worldNormal = normalWorld;

				#if defined(USE_VOLUME_LIGHT)
					float3 lDirPos = -normalize(UNITY_ACCESS_INSTANCED_PROP(InstanceProperties, _LightDirection).xyz);
					float4 lColor = UNITY_ACCESS_INSTANCED_PROP(InstanceProperties, _LightColor);
					float4 ambient = UNITY_ACCESS_INSTANCED_PROP(InstanceProperties, _AmbientColor);
				#else
					float3 lDirPos = -normalize(_LightDirection_Static.xyz);
					float4 lColor = _LightColor_Static;
					lColor.a *= _Light_Intensity_Static;
					float4 ambient = _AmbientColor_Static;
				#endif

				float nll = max(0, dot(normalWorld, lDirPos));
				nll = nll * _ShadowDarknessWeight + (1 - _ShadowDarknessWeight);
				o.lmap = (lColor.rgb * lColor.a + _WhiteIntencity) * nll + ambient.rgb * ambient.a;
				// TRANSFER_SHADOW(o)

				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				float4 albedo = tex2D(_MainTex, i.uv);

				#if defined(RECOLOR_SUPPORT)

					float recolor_Coef1 = UNITY_ACCESS_INSTANCED_PROP(InstanceProperties, _Recolor_Coef1);
					float recolor_Coef2 = UNITY_ACCESS_INSTANCED_PROP(InstanceProperties, _Recolor_Coef2);
					float4 recolor_Color = UNITY_ACCESS_INSTANCED_PROP(InstanceProperties, _Recolor);
					float recolor_Work = UNITY_ACCESS_INSTANCED_PROP(InstanceProperties, _Recolor_Work);

					half3 mColor = Luminance(albedo.rgb);

					//return dot(albedo.rgb, float3(0.299,0.587,0.114));

					mColor = (mColor - 0.5f) * 0.5f + 0.5f;
					mColor = saturate(0.5f + mColor * 2 - 1);
					//half brightness = recolor_Coef1 * 2 - 1;
					//half contrast = recolor_Coef2 * 2;
					//half3 recolored = (mColor - 0.5f) * contrast + 0.5f + brightness;

					albedo.rgb = lerp(albedo.rgb, mColor * recolor_Color, albedo.a * recolor_Color.a);
				#endif

				albedo.rgb *= i.lmap;

				float3 normal = normalize(i.worldNormal);
				float3 viewDir = normalize(i.viewDir);

				// Lighting below is calculated using Blinn-Phong,
				// with values thresholded to creat the "toon" look.
				// https://en.wikipedia.org/wiki/Blinn-Phong_shading_model

				// Calculate illumination from directional light.
				// _WorldSpaceLightPos0 is a vector pointing the OPPOSITE
				// direction of the main directional light.
				float NdotL = dot(_WorldSpaceLightPos0, normal);

				// Samples the shadow map, returning a value in the 0...1 range,
				// where 0 is in the shadow, and 1 is not.
				// Partition the intensity into light and dark, smoothly interpolated
				// between the two to avoid a jagged break.
				float lightIntensity = smoothstep( 0, 0.01, NdotL);

				// Multiply by the main directional light's intensity and color.
				float4 light = lightIntensity * _LightColor0;

				// Calculate specular reflection.
				float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);
				float NdotH = dot(normal, halfVector);
				// Multiply _Glossiness by itself to allow artist to use smaller
				// glossiness values in the inspector.
				float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness);
				float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity);
				float4 specular = specularIntensitySmooth * _SpecularColor;

				// Calculate rim lighting.
				float rimDot = 1 - dot(viewDir, normal);
				// We only want rim to appear on the lit side of the surface,
				// so multiply it by NdotL, raised to a power to smoothly blend it.
				float rimIntensity = rimDot * pow(NdotL, _RimThreshold);
				rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
				float4 rim = rimIntensity * _RimColor;

				//Halftone sample
				float4 halftone_t = tex2D(_HalftoneTex, (i.viewDir - 0.5) * _Halftone_Scale + 0.5);
				// Blend
				halftone_t *= _HalftoneColor;
				halftone_t.rbg *= halftone_t.a;

				albedo *= max((light + specular + rim), float4(_ShadowIntensity.rgb, 1));

				// Surface Halftone pattern
				albedo.rgb = lerp(albedo.rgb, halftone_t.rgb, halftone_t.a);
				albedo.a = _AlphaChanelValue;

				return albedo;
			}
			ENDCG
		}
	}
}
