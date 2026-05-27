// Adapted from caelestia-dots/shell (GPL-3.0)
import QtQuick
import qs.tokens

NumberAnimation {
    enum Type {
        StandardSmall = 0,
        Standard,
        StandardLarge,
        StandardExtraLarge,
        EmphasizedSmall,
        Emphasized,
        EmphasizedLarge,
        EmphasizedExtraLarge,
        FastSpatial,
        DefaultSpatial,
        SlowSpatial
    }

    property int type: Anim.Standard

    duration: {
        if (type < Anim.StandardSmall || type > Anim.SlowSpatial)
            return AnimTokens.durations.normal;

        if (type === Anim.FastSpatial)
            return AnimTokens.durations.expressiveFastSpatial;
        if (type === Anim.DefaultSpatial)
            return AnimTokens.durations.expressiveDefaultSpatial;
        if (type === Anim.SlowSpatial)
            return AnimTokens.durations.expressiveSlowSpatial;

        const types = ["small", "normal", "large", "extraLarge"];
        const idx = type % 4;
        return AnimTokens.durations[types[idx]];
    }

    easing: {
        if (type === Anim.FastSpatial)
            return AnimTokens.expressiveFastSpatial;
        if (type === Anim.DefaultSpatial)
            return AnimTokens.expressiveDefaultSpatial;
        if (type === Anim.SlowSpatial)
            return AnimTokens.expressiveSlowSpatial;

        if (type >= Anim.EmphasizedSmall && type <= Anim.EmphasizedExtraLarge)
            return AnimTokens.emphasized;
        return AnimTokens.standard;
    }
}
