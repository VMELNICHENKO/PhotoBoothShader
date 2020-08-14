using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(PostProcessOutline2Renderer), PostProcessEvent.BeforeStack, "PhotoBooth/Outline")]
public sealed class PostProcessOutline2 : PostProcessEffectSettings
{
    // [Tooltip("Number of pixels between samples that are tested for an edge. When this value is 1, tested samples are adjacent.")]
    public FloatParameter size_inner = new FloatParameter { value = 1.0f };
    public ColorParameter color_inner = new ColorParameter { value = Color.black };
    public FloatParameter size_outer = new FloatParameter { value = 2.0f };
    public ColorParameter color_outer = new ColorParameter { value = Color.white };
    public FloatParameter inner_shift_x = new FloatParameter { value = 0.0f };
    public FloatParameter inner_shift_y = new FloatParameter { value = 0.0f };
    public FloatParameter outer_shift_x = new FloatParameter { value = 0.0f };
    public FloatParameter outer_shift_y = new FloatParameter { value = 0.0f };
}

public sealed class PostProcessOutline2Renderer : PostProcessEffectRenderer<PostProcessOutline2>
{
    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("CSShop/PhotoBooth/Outline"));
        sheet.properties.SetFloat("_Size_Inner", settings.size_inner);
        sheet.properties.SetColor("_Color_Inner", settings.color_inner);
        sheet.properties.SetFloat("_Size_Outer", settings.size_outer);
        sheet.properties.SetColor("_Color_Outer", settings.color_outer);
        sheet.properties.SetFloat("_Shift_Inner_X", settings.inner_shift_x);
        sheet.properties.SetFloat("_Shift_Inner_Y", settings.inner_shift_y);

        sheet.properties.SetFloat("_Shift_Outer_X", settings.outer_shift_x);
        sheet.properties.SetFloat("_Shift_Outer_Y", settings.outer_shift_y);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}