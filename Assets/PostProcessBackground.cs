using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(PostProcessBackgroundRenderer), PostProcessEvent.BeforeStack, "PhotoBooth/Background")]
public sealed class PostProcessBackground : PostProcessEffectSettings
{
    public TextureParameter back_tex = new TextureParameter();
public ColorParameter color_R = new ColorParameter();
public ColorParameter color_G = new ColorParameter();

    // public TextureParameter color_tex = new TextureParameter();
}

public sealed class PostProcessBackgroundRenderer : PostProcessEffectRenderer<PostProcessBackground>
{
    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("CSShop/PhotoBooth/Background"));
        sheet.properties.SetTexture("_BackTex", settings.back_tex);
        sheet.properties.SetColor("_ColorR", settings.color_R);
        sheet.properties.SetColor("_ColorG", settings.color_G);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}