using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(PostProcessHalftoneRenderer), PostProcessEvent.BeforeStack, "PhotoBooth/Halftone")]
public sealed class PostProcessHalftone : PostProcessEffectSettings
{
    public TextureParameter halftone_tex = new TextureParameter();
    public FloatParameter threshold = new FloatParameter{ value = 0.5f};

}

public sealed class PostProcessHalftoneRenderer : PostProcessEffectRenderer<PostProcessHalftone>
{
    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("CSShop/PhotoBooth/Halftone"));
        sheet.properties.SetFloat("_Threshold", settings.threshold);
        sheet.properties.SetTexture("_HalftoneTex", settings.halftone_tex);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}