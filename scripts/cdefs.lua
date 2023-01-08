local cdefs = include("client_defs")

cdefs.BACKSTAB = {}

cdefs.BACKSTAB.OVERLAYTILES = {
    -- 384x216 pixels, tiles are 24x24 pixels
    file = "data/images/backstab/overlaytiles.png",
    -- Tile indices corresponding to the start of an animation
    animRoots = {
        -- tactical overview tiles
        {root = 1, anim = "A"},
        {root = 49, anim = "A"},
        {root = 97, anim = "A"},

        -- normal tiles
        {root = 9, anim = "A"},
        {root = 17, anim = "A"},
        {root = 25, anim = "A"},
        {root = 33, anim = "A"},
        {root = 41, anim = "A"},
        {root = 57, anim = "A"},
        {root = 65, anim = "A"},
        {root = 73, anim = "A"},
        {root = 81, anim = "A"},
        {root = 89, anim = "A"},
        {root = 105, anim = "A"},
        {root = 113, anim = "A"},
        {root = 121, anim = "A"},
        {root = 129, anim = "A"},
        {root = 137, anim = "A"},
    },
    maxAnimRoot = 137,
    -- Time values paired with an offset to apply to each animation root index.
    anims = {
        -- 3s cycle. On from 0.5s-2.5s, with a 0.3s transition centered on each point.
        -- (Contrast with movement zone curve. On from 0.25s-2.75s, with a 0.5s transition.)
        A = {
            {t = 0.00, offset = 7},
            {t = 0.25, offset = 6},
            {t = 0.30, offset = 5},
            {t = 0.45, offset = 4},
            {t = 0.50, offset = 3},
            {t = 0.55, offset = 2},
            {t = 0.60, offset = 1},
            {t = 0.65, offset = 0},
            {t = 2.25, offset = 1},
            {t = 2.30, offset = 2},
            {t = 2.45, offset = 3},
            {t = 2.50, offset = 4},
            {t = 2.55, offset = 5},
            {t = 2.60, offset = 6},
            {t = 2.65, offset = 7},
            {t = 3.00, offset = 7},
        },
    },
    sizeParams = {
        16, -- width in tiles
        9, -- height in tiles
        24 / 384, -- cellWidth
        24 / 216, -- cellHeight
        0.5 / 384, -- xOffset
        0.5 / 216, -- yOffset
        23 / 384, -- tileWidth
        23 / 216, -- tileHeight
    },
}
cdefs.BACKSTAB.OVERLAY = {
    -- Tactical Overview tiles
    BLUE_CELL = 1,
    YELLOW_CELL = 49,
    RED_CELL = 97,

    -- Offsets to normal tiles
    FILL_OFFSET = 8,
    VERTEDGE_OFFSET = 16,
    HORZEDGE_OFFSET = 24,
    INNERCORNER_OFFSET = 32,
    OUTERCORNER_OFFSET = 40,
}
