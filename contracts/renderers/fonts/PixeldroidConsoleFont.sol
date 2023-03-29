// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/utils/SSTORE2.sol";
import "./IFont.sol";

// Valid keys in `files` mapping.
enum FontFileKeys {
    TTF_FILE_PARTITION_1,
    TTF_FILE_PARTITION_2
}

contract PixeldroidConsoleFont is IFont {
    /// @inheritdoc IFont
    address public constant fontUploader = address(0);

    /// @inheritdoc IFont
    string public constant fontName = "pixeldroidConsole";

    /// @inheritdoc IFont
    string public constant fontFormatType = "ttf";

    /// @inheritdoc IFont
    string public constant fontWeight = "regular";

    /// @inheritdoc IFont
    string public constant fontStyle = "normal";

    /// @notice Addresses where font file chunks are stored.
    mapping(FontFileKeys => address) public files;

    constructor() {
        files[FontFileKeys.TTF_FILE_PARTITION_1] = SSTORE2.write(
            bytes(
                "data:font/ttf;charset=utf-8;base64,AAEAAAAPAIAAAwBwRFNJRwAAAAEAAF8YAAAACEZGVE1ww9syAABfSAAAABxHREVGACcAnQAAXyAAAAAmT1MvMoV5cPgAAAF4AAAAVmNtYXAtne9sAAADrAAAAZJjdnQgACICiAAABUAAAAAEZ2FzcP//AAEAAF8QAAAACGdseWbT1chOAAAGNAAAHlRoZWFk/V4ciwAAAPwAAAA2aGhlYQSIA/gAAAE0AAAAJGhtdHiTyxwiAAAB0AAAAdxsb2Nhuv3CygAABUQAAADwbWF4cADCAF0AAAFYAAAAIG5hbWW+CbEmAAAkiAAAOWBwb3N0VBTb0QAAXegAAAElAAEAAAABAABRykJEXw889QAfBAAAAAAAyHgrQQAAAADUMq4jAAD/gAGAAqoAAAAIAAIAAAAAAAAAAQAAAqr/gABcBAAAAAAAAYAAAQAAAAAAAAAAAAAAAAAAAHcAAQAAAHcALAAJAAAAAAACAAAAAQABAAAAQAAuAAAAAAABASwB9AAFAAACmQLMAAAAjwKZAswAAAHrADMBCQAAAgAGAwAAAAAAAAAAAAMAAQACAAAAAAAAAAAydHRmAEAAIDAAAwD/AABcAqoAgAAAAAEAAAAAAAABdgAiAAAAAAFVAAABQAAAAIAAQAEAAEABgABAAYAAQAGAAEABgABAAIAAQADAAEAAwABAAYAAQAGAAEAAwABAAQAAQACAAEABAABAAYAAQAEAAEABgABAAYAAQAGAAEABgABAAYAAQAFAAEABgABAAYAAQACAAEAAwABAAQAAQAFAAEABAABAAYAAQAGAAEABgABAAYAAQAGAAEABgABAAYAAQAGAAEABgABAAYAAQAEAAEABQABAAYAAQAEAAEABgABAAYAAQAGAAEABgABAAYAAQAGAAEABgABAAYAAQAGAAEABQABAAYAAQAGAAEABgABAAYAAQADAAEABAABAAMAAQAEAAEABQAAAAMAAQAGAAEABQABAAUAAQAFAAEABQABAAQAAQAFAAEABQABAAIAAQADAAEABQABAAMAAQAGAAEABQABAAUAAQAFAAEABQABAAQAAQAFAAEABAABAAUAAQAFAAEABgABAAUAAQAFAAEABQABAAQAAQACAAEABAABAAUAAQAFAAAAAgABAAUAAQAGAAEABQABAAYAAQACAAEABgABAAQAAQAGAAEABgABA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aAB0AHQAcABzADoALwAvAGcAaQB0AGgAdQBiAC4AYwBvAG0ALwBwAGkAeABlAGwAZAByAG8AaQBkAC8AZgBvAG4AdABzAC8AKQAsAAoAdwBpAHQAaAAgAFIAZQBzAGUAcgB2AGUAZAAgAEYAbwBuAHQAIABOAGEAbQBlADoAIAAiAEMAbwBuAHMAbwBsAGUAIgAuAAoACgBUAGgAaQBzACAARgBvAG4AdAAgAFMAbwBmAHQAdwBhAHIAZQAgAGkAcwAgAGwAaQBjAGUAbgBzAGUAZAAgAHUAbgBkAGUAcgAgAHQAaABlACAAUwBJAEwAIABPAHAAZQBuACAARgBvAG4AdAAgAEwAaQBjAGUAbgBzAGUALAAgAFYAZQByAHMAaQBvAG4AIAAxAC4AMQAuAAoAVABoAGkAcwAgAGwAaQBjAGUAbgBzAGUAIABpAHMAIABjAG8AcABpAGUAZAAgAGIAZQBsAG8AdwAsACAAYQBuAGQAIABpAHMAIABhAGwAcwBvACAAYQB2AGEAaQBsAGEAYgBsAGUAIAB3AGkAdABoACAAYQAgAEYAQQBRACAAYQB0ADoACgBoAHQAdABwADoALwAvAHMAYwByAGkAcAB0AHMALgBzAGkAbAAuAG8AcgBnAC8ATwBGAEwACgAKAAoALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAAoAUwBJAEwAIABPAFAARQBOACAARgBPAE4AVAAgAEwASQBDAEUATgBTAEUAIABWAGUAcgBzAGkAbwBuACAAMQAuADEAIAAtACAAMgA2ACAARgBlAGIAcgB1AGEAcgB5ACAAMgAwADAANwAKAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAKAAoAUABSAEUAQQBNAEIATABFAAoAVABoAGUAIABnAG8AYQBsAHMAIABvAGYAIAB0AGgAZQAgAE8AcABlAG4AIABGAG8AbgB0ACAATABpAGMAZQBuAHMAZQAgACgATwBGAEwAKQAgAGEAcgBlACAAdABvACAAcwB0AGkAbQB1AGwAYQB0AGUAIAB3AG8AcgBsAGQAdwBpAGQAZQAKAGQAZQB2AGUAbABvAHAAbQBlAG4AdAAgAG8AZgAgAGMAbwBsAGwAYQBiAG8AcgBhAHQAaQB2AGUAIABmAG8AbgB0ACAAcAByAG8AagBlAGMAdABzACwAIAB0AG8AIABzAHUAcABwAG8AcgB0ACAAdABoAGUAIABmAG8AbgB0ACAAYwByAGUAYQB0AGkAbwBuAAoAZQBmAGYAbwByAHQAcwAgAG8AZgAgAGEAYwBhAGQAZQBtAGkAYwAgAGEAbgBkACAAbABpAG4AZwB1AGkAcwB0AGkAYwAgAGMAbwBtAG0AdQBuAGkAdABpAGUAcwAsACAAYQBuAGQAIAB0AG8AIABwAHIAbwB2AGkAZABlACAAYQAgAGYAcgBlAGUAIABhAG4AZAAKAG8AcABlAG4AIABmAHIAYQBtAGUAdwBvAHIAawAgAGkAbgAgAHcAaABpAGMAaAAgAGYAbwBuAHQAcwAgAG0AYQB5ACAAYgBlACAAcwBoAGEAcgBlAGQAIABhAG4AZAAgAGkAbQBwAHIA"
            )
        );

        files[FontFileKeys.TTF_FILE_PARTITION_2] = SSTORE2.write(
            bytes(
                "bwB2AGUAZAAgAGkAbgAgAHAAYQByAHQAbgBlAHIAcwBoAGkAcAAKAHcAaQB0AGgAIABvAHQAaABlAHIAcwAuAAoACgBUAGgAZQAgAE8ARgBMACAAYQBsAGwAbwB3AHMAIAB0AGgAZQAgAGwAaQBjAGUAbgBzAGUAZAAgAGYAbwBuAHQAcwAgAHQAbwAgAGIAZQAgAHUAcwBlAGQALAAgAHMAdAB1AGQAaQBlAGQALAAgAG0AbwBkAGkAZgBpAGUAZAAgAGEAbgBkAAoAcgBlAGQAaQBzAHQAcgBpAGIAdQB0AGUAZAAgAGYAcgBlAGUAbAB5ACAAYQBzACAAbABvAG4AZwAgAGEAcwAgAHQAaABlAHkAIABhAHIAZQAgAG4AbwB0ACAAcwBvAGwAZAAgAGIAeQAgAHQAaABlAG0AcwBlAGwAdgBlAHMALgAgAFQAaABlAAoAZgBvAG4AdABzACwAIABpAG4AYwBsAHUAZABpAG4AZwAgAGEAbgB5ACAAZABlAHIAaQB2AGEAdABpAHYAZQAgAHcAbwByAGsAcwAsACAAYwBhAG4AIABiAGUAIABiAHUAbgBkAGwAZQBkACwAIABlAG0AYgBlAGQAZABlAGQALAAgAAoAcgBlAGQAaQBzAHQAcgBpAGIAdQB0AGUAZAAgAGEAbgBkAC8AbwByACAAcwBvAGwAZAAgAHcAaQB0AGgAIABhAG4AeQAgAHMAbwBmAHQAdwBhAHIAZQAgAHAAcgBvAHYAaQBkAGUAZAAgAHQAaABhAHQAIABhAG4AeQAgAHIAZQBzAGUAcgB2AGUAZAAKAG4AYQBtAGUAcwAgAGEAcgBlACAAbgBvAHQAIAB1AHMAZQBkACAAYgB5ACAAZABlAHIAaQB2AGEAdABpAHYAZQAgAHcAbwByAGsAcwAuACAAVABoAGUAIABmAG8AbgB0AHMAIABhAG4AZAAgAGQAZQByAGkAdgBhAHQAaQB2AGUAcwAsAAoAaABvAHcAZQB2AGUAcgAsACAAYwBhAG4AbgBvAHQAIABiAGUAIAByAGUAbABlAGEAcwBlAGQAIAB1AG4AZABlAHIAIABhAG4AeQAgAG8AdABoAGUAcgAgAHQAeQBwAGUAIABvAGYAIABsAGkAYwBlAG4AcwBlAC4AIABUAGgAZQAKAHIAZQBxAHUAaQByAGUAbQBlAG4AdAAgAGYAbwByACAAZgBvAG4AdABzACAAdABvACAAcgBlAG0AYQBpAG4AIAB1AG4AZABlAHIAIAB0AGgAaQBzACAAbABpAGMAZQBuAHMAZQAgAGQAbwBlAHMAIABuAG8AdAAgAGEAcABwAGwAeQAKAHQAbwAgAGEAbgB5ACAAZABvAGMAdQBtAGUAbgB0ACAAYwByAGUAYQB0AGUAZAAgAHUAcwBpAG4AZwAgAHQAaABlACAAZgBvAG4AdABzACAAbwByACAAdABoAGUAaQByACAAZABlAHIAaQB2AGEAdABpAHYAZQBzAC4ACgAKAEQARQBGAEkATgBJAFQASQBPAE4AUwAKACIARgBvAG4AdAAgAFMAbwBmAHQAdwBhAHIAZQAiACAAcgBlAGYAZQByAHMAIAB0AG8AIAB0AGgAZQAgAHMAZQB0ACAAbwBmACAAZgBpAGwAZQBzACAAcgBlAGwAZQBhAHMAZQBkACAAYgB5ACAAdABoAGUAIABDAG8AcAB5AHIAaQBnAGgAdAAKAEgAbwBsAGQAZQByACgAcwApACAAdQBuAGQAZQByACAAdABoAGkAcwAgAGwAaQBjAGUAbgBzAGUAIABhAG4AZAAgAGMAbABlAGEAcgBsAHkAIABtAGEAcgBrAGUAZAAgAGEAcwAgAHMAdQBjAGgALgAgAFQAaABpAHMAIABtAGEAeQAKAGkAbgBjAGwAdQBkAGUAIABzAG8AdQByAGMAZQAgAGYAaQBsAGUAcwAsACAAYgB1AGkAbABkACAAcwBjAHIAaQBwAHQAcwAgAGEAbgBkACAAZABvAGMAdQBtAGUAbgB0AGEAdABpAG8AbgAuAAoACgAiAFIAZQBzAGUAcgB2AGUAZAAgAEYAbwBuAHQAIABOAGEAbQBlACIAIAByAGUAZgBlAHIAcwAgAHQAbwAgAGEAbgB5ACAAbgBhAG0AZQBzACAAcwBwAGUAYwBpAGYAaQBlAGQAIABhAHMAIABzAHUAYwBoACAAYQBmAHQAZQByACAAdABoAGUACgBjAG8AcAB5AHIAaQBnAGgAdAAgAHMAdABhAHQAZQBtAGUAbgB0ACgAcwApAC4ACgAKACIATwByAGkAZwBpAG4AYQBsACAAVgBlAHIAcwBpAG8AbgAiACAAcgBlAGYAZQByAHMAIAB0AG8AIAB0AGgAZQAgAGMAbwBsAGwAZQBjAHQAaQBvAG4AIABvAGYAIABGAG8AbgB0ACAAUwBvAGYAdAB3AGEAcgBlACAAYwBvAG0AcABvAG4AZQBuAHQAcwAgAGEAcwAKAGQAaQBzAHQAcgBpAGIAdQB0AGUAZAAgAGIAeQAgAHQAaABlACAAQwBvAHAAeQByAGkAZwBoAHQAIABIAG8AbABkAGUAcgAoAHMAKQAuAAoACgAiAE0AbwBkAGkAZgBpAGUAZAAgAFYAZQByAHMAaQBvAG4AIgAgAHIAZQBmAGUAcgBzACAAdABvACAAYQBuAHkAIABkAGUAcgBpAHYAYQB0AGkAdgBlACAAbQBhAGQAZQAgAGIAeQAgAGEAZABkAGkAbgBnACAAdABvACwAIABkAGUAbABlAHQAaQBuAGcALAAKAG8AcgAgAHMAdQBiAHMAdABpAHQAdQB0AGkAbgBnACAALQAtACAAaQBuACAAcABhAHIAdAAgAG8AcgAgAGkAbgAgAHcAaABvAGwAZQAgAC0ALQAgAGEAbgB5ACAAbwBmACAAdABoAGUAIABjAG8AbQBwAG8AbgBlAG4AdABzACAAbwBmACAAdABoAGUACgBPAHIAaQBnAGkAbgBhAGwAIABWAGUAcgBzAGkAbwBuACwAIABiAHkAIABjAGgAYQBuAGcAaQBuAGcAIABmAG8AcgBtAGEAdABzACAAbwByACAAYgB5ACAAcABvAHIAdABpAG4AZwAgAHQAaABlACAARgBvAG4AdAAgAFMAbwBmAHQAdwBhAHIAZQAgAHQAbwAgAGEACgBuAGUAdwAgAGUAbgB2AGkAcgBvAG4AbQBlAG4AdAAuAAoACgAiAEEAdQB0AGgAbwByACIAIAByAGUAZgBlAHIAcwAgAHQAbwAgAGEAbgB5ACAAZABlAHMAaQBnAG4AZQByACwAIABlAG4AZwBpAG4AZQBlAHIALAAgAHAAcgBvAGcAcgBhAG0AbQBlAHIALAAgAHQAZQBjAGgAbgBpAGMAYQBsAAoAdwByAGkAdABlAHIAIABvAHIAIABvAHQAaABlAHIAIABwAGUAcgBzAG8AbgAgAHcAaABvACAAYwBvAG4AdAByAGkAYgB1AHQAZQBkACAAdABvACAAdABoAGUAIABGAG8AbgB0ACAAUwBvAGYAdAB3AGEAcgBlAC4ACgAKAFAARQBSAE0ASQBTAFMASQBPAE4AIAAmACAAQwBPAE4ARABJAFQASQBPAE4AUwAKAFAAZQByAG0AaQBzAHMAaQBvAG4AIABpAHMAIABoAGUAcgBlAGIAeQAgAGcAcgBhAG4AdABlAGQALAAgAGYAcgBlAGUAIABvAGYAIABjAGgAYQByAGcAZQAsACAAdABvACAAYQBuAHkAIABwAGUAcgBzAG8AbgAgAG8AYgB0AGEAaQBuAGkAbgBnAAoAYQAgAGMAbwBwAHkAIABvAGYAIAB0AGgAZQAgAEYAbwBuAHQAIABTAG8AZgB0AHcAYQByAGUALAAgAHQAbwAgAHUAcwBlACwAIABzAHQAdQBkAHkALAAgAGMAbwBwAHkALAAgAG0AZQByAGcAZQAsACAAZQBtAGIAZQBkACwAIABtAG8AZABpAGYAeQAsAAoAcgBlAGQAaQBzAHQAcgBpAGIAdQB0AGUALAAgAGEAbgBkACAAcwBlAGwAbAAgAG0AbwBkAGkAZgBpAGUAZAAgAGEAbgBkACAAdQBuAG0AbwBkAGkAZgBpAGUAZAAgAGMAbwBwAGkAZQBzACAAbwBmACAAdABoAGUAIABGAG8AbgB0AAoAUwBvAGYAdAB3AGEAcgBlACwAIABzAHUAYgBqAGUAYwB0ACAAdABvACAAdABoAGUAIABmAG8AbABsAG8AdwBpAG4AZwAgAGMAbwBuAGQAaQB0AGkAbwBuAHMAOgAKAAoAMQApACAATgBlAGkAdABoAGUAcgAgAHQAaABlACAARgBvAG4AdAAgAFMAbwBmAHQAdwBhAHIAZQAgAG4AbwByACAAYQBuAHkAIABvAGYAIABpAHQAcwAgAGkAbgBkAGkAdgBpAGQAdQBhAGwAIABjAG8AbQBwAG8AbgBlAG4AdABzACwACgBpAG4AIABPAHIAaQBnAGkAbgBhAGwAIABvAHIAIABNAG8AZABpAGYAaQBlAGQAIABWAGUAcgBzAGkAbwBuAHMALAAgAG0AYQB5ACAAYgBlACAAcwBvAGwAZAAgAGIAeQAgAGkAdABzAGUAbABmAC4ACgAKADIAKQAgAE8AcgBpAGcAaQBuAGEAbAAgAG8AcgAgAE0AbwBkAGkAZgBpAGUAZAAgAFYAZQByAHMAaQBvAG4AcwAgAG8AZgAgAHQAaABlACAARgBvAG4AdAAgAFMAbwBmAHQAdwBhAHIAZQAgAG0AYQB5ACAAYgBlACAAYgB1AG4AZABsAGUAZAAsAAoAcgBlAGQAaQBzAHQAcgBpAGIAdQB0AGUAZAAgAGEAbgBkAC8AbwByACAAcwBvAGwAZAAgAHcAaQB0AGgAIABhAG4AeQAgAHMAbwBmAHQAdwBhAHIAZQAsACAAcAByAG8AdgBpAGQAZQBkACAAdABoAGEAdAAgAGUAYQBjAGgAIABjAG8AcAB5AAoAYwBvAG4AdABhAGkAbgBzACAAdABoAGUAIABhAGIAbwB2AGUAIABjAG8AcAB5AHIAaQBnAGgAdAAgAG4AbwB0AGkAYwBlACAAYQBuAGQAIAB0AGgAaQBzACAAbABpAGMAZQBuAHMAZQAuACAAVABoAGUAcwBlACAAYwBhAG4AIABiAGUACgBpAG4AYwBsAHUAZABlAGQAIABlAGkAdABoAGUAcgAgAGEAcwAgAHMAdABhAG4AZAAtAGEAbABvAG4AZQAgAHQAZQB4AHQAIABmAGkAbABlAHMALAAgAGgAdQBtAGEAbgAtAHIAZQBhAGQAYQBiAGwAZQAgAGgAZQBhAGQAZQByAHMAIABvAHIACgBpAG4AIAB0AGgAZQAgAGEAcABwAHIAbwBwAHIAaQBhAHQAZQAgAG0AYQBjAGgAaQBuAGUALQByAGUAYQBkAGEAYgBsAGUAIABtAGUAdABhAGQAYQB0AGEAIABmAGkAZQBsAGQAcwAgAHcAaQB0AGgAaQBuACAAdABlAHgAdAAgAG8AcgAKAGIAaQBuAGEAcgB5ACAAZgBpAGwAZQBzACAAYQBzACAAbABvAG4AZwAgAGEAcwAgAHQAaABvAHMAZQAgAGYAaQBlAGwAZABzACAAYwBhAG4AIABiAGUAIABlAGEAcwBpAGwAeQAgAHYAaQBlAHcAZQBkACAAYgB5ACAAdABoAGUAIAB1AHMAZQByAC4ACgAKADMAKQAgAE4AbwAgAE0AbwBkAGkAZgBpAGUAZAAgAFYAZQByAHMAaQBvAG4AIABvAGYAIAB0AGgAZQAgAEYAbwBuAHQAIABTAG8AZgB0AHcAYQByAGUAIABtAGEAeQAgAHUAcwBlACAAdABoAGUAIABSAGUAcwBlAHIAdgBlAGQAIABGAG8AbgB0AAoATgBhAG0AZQAoAHMAKQAgAHUAbgBsAGUAcwBzACAAZQB4AHAAbABpAGMAaQB0ACAAdwByAGkAdAB0AGUAbgAgAHAAZQByAG0AaQBzAHMAaQBvAG4AIABpAHMAIABnAHIAYQBuAHQAZQBkACAAYgB5ACAAdABoAGUAIABjAG8AcgByAGUAcwBwAG8AbgBkAGkAbgBnAAoAQwBvAHAAeQByAGkAZwBoAHQAIABIAG8AbABkAGUAcgAuACAAVABoAGkAcwAgAHIAZQBzAHQAcgBpAGMAdABpAG8AbgAgAG8AbgBsAHkAIABhAHAAcABsAGkAZQBzACAAdABvACAAdABoAGUAIABwAHIAaQBtAGEAcgB5ACAAZgBvAG4AdAAgAG4AYQBtAGUAIABhAHMACgBwAHIAZQBzAGUAbgB0AGUAZAAgAHQAbwAgAHQAaABlACAAdQBzAGUAcgBzAC4ACgAKADQAKQAgAFQAaABlACAAbgBhAG0AZQAoAHMAKQAgAG8AZgAgAHQAaABlACAAQwBvAHAAeQByAGkAZwBoAHQAIABIAG8AbABkAGUAcgAoAHMAKQAgAG8AcgAgAHQAaABlACAAQQB1AHQAaABvAHIAKABzACkAIABvAGYAIAB0AGgAZQAgAEYAbwBuAHQACgBTAG8AZgB0AHcAYQByAGUAIABzAGgAYQBsAGwAIABuAG8AdAAgAGIAZQAgAHUAcwBlAGQAIAB0AG8AIABwAHIAbwBtAG8AdABlACwAIABlAG4AZABvAHIAcwBlACAAbwByACAAYQBkAHYAZQByAHQAaQBzAGUAIABhAG4AeQAKAE0AbwBkAGkAZgBpAGUAZAAgAFYAZQByAHMAaQBvAG4ALAAgAGUAeABjAGUAcAB0ACAAdABvACAAYQBjAGsAbgBvAHcAbABlAGQAZwBlACAAdABoAGUAIABjAG8AbgB0AHIAaQBiAHUAdABpAG8AbgAoAHMAKQAgAG8AZgAgAHQAaABlAAoAQwBvAHAAeQByAGkAZwBoAHQAIABIAG8AbABkAGUAcgAoAHMAKQAgAGEAbgBkACAAdABoAGUAIABBAHUAdABoAG8AcgAoAHMAKQAgAG8AcgAgAHcAaQB0AGgAIAB0AGgAZQBpAHIAIABlAHgAcABsAGkAYwBpAHQAIAB3AHIAaQB0AHQAZQBuAAoAcABlAHIAbQBpAHMAcwBpAG8AbgAuAAoACgA1ACkAIABUAGgAZQAgAEYAbwBuAHQAIABTAG8AZgB0AHcAYQByAGUALAAgAG0AbwBkAGkAZgBpAGUAZAAgAG8AcgAgAHUAbgBtAG8AZABpAGYAaQBlAGQALAAgAGkAbgAgAHAAYQByAHQAIABvAHIAIABpAG4AIAB3AGgAbwBsAGUALAAKAG0AdQBzAHQAIABiAGUAIABkAGkAcwB0AHIAaQBiAHUAdABlAGQAIABlAG4AdABpAHIAZQBsAHkAIAB1AG4AZABlAHIAIAB0AGgAaQBzACAAbABpAGMAZQBuAHMAZQAsACAAYQBuAGQAIABtAHUAcwB0ACAAbgBvAHQAIABiAGUACgBkAGkAcwB0AHIAaQBiAHUAdABlAGQAIAB1AG4AZABlAHIAIABhAG4AeQAgAG8AdABoAGUAcgAgAGwAaQBjAGUAbgBzAGUALgAgAFQAaABlACAAcgBlAHEAdQBpAHIAZQBtAGUAbgB0ACAAZgBvAHIAIABmAG8AbgB0AHMAIAB0AG8ACgByAGUAbQBhAGkAbgAgAHUAbgBkAGUAcgAgAHQAaABpAHMAIABsAGkAYwBlAG4AcwBlACAAZABvAGUAcwAgAG4AbwB0ACAAYQBwAHAAbAB5ACAAdABvACAAYQBuAHkAIABkAG8AYwB1AG0AZQBuAHQAIABjAHIAZQBhAHQAZQBkAAoAdQBzAGkAbgBnACAAdABoAGUAIABGAG8AbgB0ACAAUwBvAGYAdAB3AGEAcgBlAC4ACgAKAFQARQBSAE0ASQBOAEEAVABJAE8ATgAKAFQAaABpAHMAIABsAGkAYwBlAG4AcwBlACAAYgBlAGMAbwBtAGUAcwAgAG4AdQBsAGwAIABhAG4AZAAgAHYAbwBpAGQAIABpAGYAIABhAG4AeQAgAG8AZgAgAHQAaABlACAAYQBiAG8AdgBlACAAYwBvAG4AZABpAHQAaQBvAG4AcwAgAGEAcgBlAAoAbgBvAHQAIABtAGUAdAAuAAoACgBEAEkAUwBDAEwAQQBJAE0ARQBSAAoAVABIAEUAIABGAE8ATgBUACAAUwBPAEYAVABXAEEAUgBFACAASQBTACAAUABSAE8AVgBJAEQARQBEACAAIgBBAFMAIABJAFMAIgAsACAAVwBJAFQASABPAFUAVAAgAFcAQQBSAFIAQQBOAFQAWQAgAE8ARgAgAEEATgBZACAASwBJAE4ARAAsAAoARQBYAFAAUgBFAFMAUwAgAE8AUgAgAEkATQBQAEwASQBFAEQALAAgAEkATgBDAEwAVQBEAEkATgBHACAAQgBVAFQAIABOAE8AVAAgAEwASQBNAEkAVABFAEQAIABUAE8AIABBAE4AWQAgAFcAQQBSAFIAQQBOAFQASQBFAFMAIABPAEYACgBNAEUAUgBDAEgAQQBOAFQAQQBCAEkATABJAFQAWQAsACAARgBJAFQATgBFAFMAUwAgAEYATwBSACAAQQAgAFAAQQBSAFQASQBDAFUATABBAFIAIABQAFUAUgBQAE8AUwBFACAAQQBOAEQAIABOAE8ATgBJAE4ARgBSAEkATgBHAEUATQBFAE4AVAAKAE8ARgAgAEMATwBQAFkAUgBJAEcASABUACwAIABQAEEAVABFAE4AVAAsACAAVABSAEEARABFAE0AQQBSAEsALAAgAE8AUgAgAE8AVABIAEUAUgAgAFIASQBHAEgAVAAuACAASQBOACAATgBPACAARQBWAEUATgBUACAAUwBIAEEATABMACAAVABIAEUACgBDAE8AUABZAFIASQBHAEgAVAAgAEgATwBMAEQARQBSACAAQgBFACAATABJAEEAQgBMAEUAIABGAE8AUgAgAEEATgBZACAAQwBMAEEASQBNACwAIABEAEEATQBBAEcARQBTACAATwBSACAATwBUAEgARQBSACAATABJAEEAQgBJAEwASQBUAFkALAAKAEkATgBDAEwAVQBEAEkATgBHACAAQQBOAFkAIABHAEUATgBFAFIAQQBMACwAIABTAFAARQBDAEkAQQBMACwAIABJAE4ARABJAFIARQBDAFQALAAgAEkATgBDAEkARABFAE4AVABBAEwALAAgAE8AUgAgAEMATwBOAFMARQBRAFUARQBOAFQASQBBAEwACgBEAEEATQBBAEcARQBTACwAIABXAEgARQBUAEgARQBSACAASQBOACAAQQBOACAAQQBDAFQASQBPAE4AIABPAEYAIABDAE8ATgBUAFIAQQBDAFQALAAgAFQATwBSAFQAIABPAFIAIABPAFQASABFAFIAVwBJAFMARQAsACAAQQBSAEkAUwBJAE4ARwAKAEYAUgBPAE0ALAAgAE8AVQBUACAATwBGACAAVABIAEUAIABVAFMARQAgAE8AUgAgAEkATgBBAEIASQBMAEkAVABZACAAVABPACAAVQBTAEUAIABUAEgARQAgAEYATwBOAFQAIABTAE8ARgBUAFcAQQBSAEUAIABPAFIAIABGAFIATwBNAAoATwBUAEgARQBSACAARABFAEEATABJAE4ARwBTACAASQBOACAAVABIAEUAIABGAE8ATgBUACAAUwBPAEYAVABXAEEAUgBFAC4AAENvcHlyaWdodCAoYykgcGl4ZWxkcm9pZCAoaHR0cHM6Ly9naXRodWIuY29tL3BpeGVsZHJvaWQvZm9udHMvKSwKd2l0aCBSZXNlcnZlZCBGb250IE5hbWU6ICJDb25zb2xlIi4KClRoaXMgRm9udCBTb2Z0d2FyZSBpcyBsaWNlbnNlZCB1bmRlciB0aGUgU0lMIE9wZW4gRm9udCBMaWNlbnNlLCBWZXJzaW9uIDEuMS4KVGhpcyBsaWNlbnNlIGlzIGNvcGllZCBiZWxvdywgYW5kIGlzIGFsc28gYXZhaWxhYmxlIHdpdGggYSBGQVEgYXQ6Cmh0dHA6Ly9zY3JpcHRzLnNpbC5vcmcvT0ZMCgoKLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KU0lMIE9QRU4gRk9OVCBMSUNFTlNFIFZlcnNpb24gMS4xIC0gMjYgRmVicnVhcnkgMjAwNwotLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQoKUFJFQU1CTEUKVGhlIGdvYWxzIG9mIHRoZSBPcGVuIEZvbnQgTGljZW5zZSAoT0ZMKSBhcmUgdG8gc3RpbXVsYXRlIHdvcmxkd2lkZQpkZXZlbG9wbWVudCBvZiBjb2xsYWJvcmF0aXZlIGZvbnQgcHJvamVjdHMsIHRvIHN1cHBvcnQgdGhlIGZvbnQgY3JlYXRpb24KZWZmb3J0cyBvZiBhY2FkZW1pYyBhbmQgbGluZ3Vpc3RpYyBjb21tdW5pdGllcywgYW5kIHRvIHByb3ZpZGUgYSBmcmVlIGFuZApvcGVuIGZyYW1ld29yayBpbiB3aGljaCBmb250cyBtYXkgYmUgc2hhcmVkIGFuZCBpbXByb3ZlZCBpbiBwYXJ0bmVyc2hpcAp3aXRoIG90aGVycy4KClRoZSBPRkwgYWxsb3dzIHRoZSBsaWNlbnNlZCBmb250cyB0byBiZSB1c2VkLCBzdHVkaWVkLCBtb2RpZmllZCBhbmQKcmVkaXN0cmlidXRlZCBmcmVlbHkgYXMgbG9uZyBhcyB0aGV5IGFyZSBub3Qgc29sZCBieSB0aGVtc2VsdmVzLiBUaGUKZm9udHMsIGluY2x1ZGluZyBhbnkgZGVyaXZhdGl2ZSB3b3JrcywgY2FuIGJlIGJ1bmRsZWQsIGVtYmVkZGVkLCAKcmVkaXN0cmlidXRlZCBhbmQvb3Igc29sZCB3aXRoIGFueSBzb2Z0d2FyZSBwcm92aWRlZCB0aGF0IGFueSByZXNlcnZlZApuYW1lcyBhcmUgbm90IHVzZWQgYnkgZGVyaXZhdGl2ZSB3b3Jrcy4gVGhlIGZvbnRzIGFuZCBkZXJpdmF0aXZlcywKaG93ZXZlciwgY2Fubm90IGJlIHJlbGVhc2VkIHVuZGVyIGFueSBvdGhlciB0eXBlIG9mIGxpY2Vuc2UuIFRoZQpyZXF1aXJlbWVudCBmb3IgZm9udHMgdG8gcmVtYWluIHVuZGVyIHRoaXMgbGljZW5zZSBkb2VzIG5vdCBhcHBseQp0byBhbnkgZG9jdW1lbnQgY3JlYXRlZCB1c2luZyB0aGUgZm9udHMgb3IgdGhlaXIgZGVyaXZhdGl2ZXMuCgpERUZJTklUSU9OUwoiRm9udCBTb2Z0d2FyZSIgcmVmZXJzIHRvIHRoZSBzZXQgb2YgZmlsZXMgcmVsZWFzZWQgYnkgdGhlIENvcHlyaWdodApIb2xkZXIocykgdW5kZXIgdGhpcyBsaWNlbnNlIGFuZCBjbGVhcmx5IG1hcmtlZCBhcyBzdWNoLiBUaGlzIG1heQppbmNsdWRlIHNvdXJjZSBmaWxlcywgYnVpbGQgc2NyaXB0cyBhbmQgZG9jdW1lbnRhdGlvbi4KCiJSZXNlcnZlZCBGb250IE5hbWUiIHJlZmVycyB0byBhbnkgbmFtZXMgc3BlY2lmaWVkIGFzIHN1Y2ggYWZ0ZXIgdGhlCmNvcHlyaWdodCBzdGF0ZW1lbnQocykuCgoiT3JpZ2luYWwgVmVyc2lvbiIgcmVmZXJzIHRvIHRoZSBjb2xsZWN0aW9uIG9mIEZvbnQgU29mdHdhcmUgY29tcG9uZW50cyBhcwpkaXN0cmlidXRlZCBieSB0aGUgQ29weXJpZ2h0IEhvbGRlcihzKS4KCiJNb2RpZmllZCBWZXJzaW9uIiByZWZlcnMgdG8gYW55IGRlcml2YXRpdmUgbWFkZSBieSBhZGRpbmcgdG8sIGRlbGV0aW5nLApvciBzdWJzdGl0dXRpbmcgLS0gaW4gcGFydCBvciBpbiB3aG9sZSAtLSBhbnkgb2YgdGhlIGNvbXBvbmVudHMgb2YgdGhlCk9yaWdpbmFsIFZlcnNpb24sIGJ5IGNoYW5naW5nIGZvcm1hdHMgb3IgYnkgcG9ydGluZyB0aGUgRm9udCBTb2Z0d2FyZSB0byBhCm5ldyBlbnZpcm9ubWVudC4KCiJBdXRob3IiIHJlZmVycyB0byBhbnkgZGVzaWduZXIsIGVuZ2luZWVyLCBwcm9ncmFtbWVyLCB0ZWNobmljYWwKd3JpdGVyIG9yIG90aGVyIHBlcnNvbiB3aG8gY29udHJpYnV0ZWQgdG8gdGhlIEZvbnQgU29mdHdhcmUuCgpQRVJNSVNTSU9OICYgQ09ORElUSU9OUwpQZXJtaXNzaW9uIGlzIGhlcmVieSBncmFudGVkLCBmcmVlIG9mIGNoYXJnZSwgdG8gYW55IHBlcnNvbiBvYnRhaW5pbmcKYSBjb3B5IG9mIHRoZSBGb250IFNvZnR3YXJlLCB0byB1c2UsIHN0dWR5LCBjb3B5LCBtZXJnZSwgZW1iZWQsIG1vZGlmeSwKcmVkaXN0cmlidXRlLCBhbmQgc2VsbCBtb2RpZmllZCBhbmQgdW5tb2RpZmllZCBjb3BpZXMgb2YgdGhlIEZvbnQKU29mdHdhcmUsIHN1YmplY3QgdG8gdGhlIGZvbGxvd2luZyBjb25kaXRpb25zOgoKMSkgTmVpdGhlciB0aGUgRm9udCBTb2Z0d2FyZSBub3IgYW55IG9mIGl0cyBpbmRpdmlkdWFsIGNvbXBvbmVudHMsCmluIE9yaWdpbmFsIG9yIE1vZGlmaWVkIFZlcnNpb25zLCBtYXkgYmUgc29sZCBieSBpdHNlbGYuCgoyKSBPcmlnaW5hbCBvciBNb2RpZmllZCBWZXJzaW9ucyBvZiB0aGUgRm9udCBTb2Z0d2FyZSBtYXkgYmUgYnVuZGxlZCwKcmVkaXN0cmlidXRlZCBhbmQvb3Igc29sZCB3aXRoIGFueSBzb2Z0d2FyZSwgcHJvdmlkZWQgdGhhdCBlYWNoIGNvcHkKY29udGFpbnMgdGhlIGFib3ZlIGNvcHlyaWdodCBub3RpY2UgYW5kIHRoaXMgbGljZW5zZS4gVGhlc2UgY2FuIGJlCmluY2x1ZGVkIGVpdGhlciBhcyBzdGFuZC1hbG9uZSB0ZXh0IGZpbGVzLCBodW1hbi1yZWFkYWJsZSBoZWFkZXJzIG9yCmluIHRoZSBhcHByb3ByaWF0ZSBtYWNoaW5lLXJlYWRhYmxlIG1ldGFkYXRhIGZpZWxkcyB3aXRoaW4gdGV4dCBvcgpiaW5hcnkgZmlsZXMgYXMgbG9uZyBhcyB0aG9zZSBmaWVsZHMgY2FuIGJlIGVhc2lseSB2aWV3ZWQgYnkgdGhlIHVzZXIuCgozKSBObyBNb2RpZmllZCBWZXJzaW9uIG9mIHRoZSBGb250IFNvZnR3YXJlIG1heSB1c2UgdGhlIFJlc2VydmVkIEZvbnQKTmFtZShzKSB1bmxlc3MgZXhwbGljaXQgd3JpdHRlbiBwZXJtaXNzaW9uIGlzIGdyYW50ZWQgYnkgdGhlIGNvcnJlc3BvbmRpbmcKQ29weXJpZ2h0IEhvbGRlci4gVGhpcyByZXN0cmljdGlvbiBvbmx5IGFwcGxpZXMgdG8gdGhlIHByaW1hcnkgZm9udCBuYW1lIGFzCnByZXNlbnRlZCB0byB0aGUgdXNlcnMuCgo0KSBUaGUgbmFtZShzKSBvZiB0aGUgQ29weXJpZ2h0IEhvbGRlcihzKSBvciB0aGUgQXV0aG9yKHMpIG9mIHRoZSBGb250ClNvZnR3YXJlIHNoYWxsIG5vdCBiZSB1c2VkIHRvIHByb21vdGUsIGVuZG9yc2Ugb3IgYWR2ZXJ0aXNlIGFueQpNb2RpZmllZCBWZXJzaW9uLCBleGNlcHQgdG8gYWNrbm93bGVkZ2UgdGhlIGNvbnRyaWJ1dGlvbihzKSBvZiB0aGUKQ29weXJpZ2h0IEhvbGRlcihzKSBhbmQgdGhlIEF1dGhvcihzKSBvciB3aXRoIHRoZWlyIGV4cGxpY2l0IHdyaXR0ZW4KcGVybWlzc2lvbi4KCjUpIFRoZSBGb250IFNvZnR3YXJlLCBtb2RpZmllZCBvciB1bm1vZGlmaWVkLCBpbiBwYXJ0IG9yIGluIHdob2xlLAptdXN0IGJlIGRpc3RyaWJ1dGVkIGVudGlyZWx5IHVuZGVyIHRoaXMgbGljZW5zZSwgYW5kIG11c3Qgbm90IGJlCmRpc3RyaWJ1dGVkIHVuZGVyIGFueSBvdGhlciBsaWNlbnNlLiBUaGUgcmVxdWlyZW1lbnQgZm9yIGZvbnRzIHRvCnJlbWFpbiB1bmRlciB0aGlzIGxpY2Vuc2UgZG9lcyBub3QgYXBwbHkgdG8gYW55IGRvY3VtZW50IGNyZWF0ZWQKdXNpbmcgdGhlIEZvbnQgU29mdHdhcmUuCgpURVJNSU5BVElPTgpUaGlzIGxpY2Vuc2UgYmVjb21lcyBudWxsIGFuZCB2b2lkIGlmIGFueSBvZiB0aGUgYWJvdmUgY29uZGl0aW9ucyBhcmUKbm90IG1ldC4KCkRJU0NMQUlNRVIKVEhFIEZPTlQgU09GVFdBUkUgSVMgUFJPVklERUQgIkFTIElTIiwgV0lUSE9VVCBXQVJSQU5UWSBPRiBBTlkgS0lORCwKRVhQUkVTUyBPUiBJTVBMSUVELCBJTkNMVURJTkcgQlVUIE5PVCBMSU1JVEVEIFRPIEFOWSBXQVJSQU5USUVTIE9GCk1FUkNIQU5UQUJJTElUWSwgRklUTkVTUyBGT1IgQSBQQVJUSUNVTEFSIFBVUlBPU0UgQU5EIE5PTklORlJJTkdFTUVOVApPRiBDT1BZUklHSFQsIFBBVEVOVCwgVFJBREVNQVJLLCBPUiBPVEhFUiBSSUdIVC4gSU4gTk8gRVZFTlQgU0hBTEwgVEhFCkNPUFlSSUdIVCBIT0xERVIgQkUgTElBQkxFIEZPUiBBTlkgQ0xBSU0sIERBTUFHRVMgT1IgT1RIRVIgTElBQklMSVRZLApJTkNMVURJTkcgQU5ZIEdFTkVSQUwsIFNQRUNJQUwsIElORElSRUNULCBJTkNJREVOVEFMLCBPUiBDT05TRVFVRU5USUFMCkRBTUFHRVMsIFdIRVRIRVIgSU4gQU4gQUNUSU9OIE9GIENPTlRSQUNULCBUT1JUIE9SIE9USEVSV0lTRSwgQVJJU0lORwpGUk9NLCBPVVQgT0YgVEhFIFVTRSBPUiBJTkFCSUxJVFkgVE8gVVNFIFRIRSBGT05UIFNPRlRXQVJFIE9SIEZST00KT1RIRVIgREVBTElOR1MgSU4gVEhFIEZPTlQgU09GVFdBUkUuAABoAHQAdABwADoALwAvAHMAYwByAGkAcAB0AHMALgBzAGkAbAAuAG8AcgBnAC8ATwBGAEwAAGh0dHA6Ly9zY3JpcHRzLnNpbC5vcmcvT0ZMAAACAAAAAAAA/04AMwAAAAAAAAAAAAAAAAAAAAAAAAAAAHcAAAABAAIAAwAEAAUABgAHAAgACQAKAAsADAANAA4ADwAQABEAEgATABQAFQAWABcAGAAZABoAGwAcAB0AHgAfACAAIQAiACMAJAAlACYAJwAoACkAKgArACwALQAuAC8AMAAxADIAMwA0ADUANgA3ADgAOQA6ADsAPAA9AD4APwBAAEEAQgBDAEQARQBGAEcASABJAEoASwBMAE0ATgBPAFAAUQBSAFMAVABVAFYAVwBYAFkAWgBbAFwAXQBeAF8AYABhAQIAowCEAIUAvQCWAOgAhgCOAIsAqQCKAIMAwwCqAPAAkQC4AKEBAwEEB3VuaTAwQTAERXVybwd1bmkzMDAwAAAAAAAAAf//AAAAAAABAAAAAAABAAAADAAAABYAHgACAAEAAQB2AAEABAAAAAIAAAABAAAAAQAAAAAAAAABAAAAANQZAc0AAAAAyHgrQQAAAADUMq4j"
            )
        );
    }

    /// @inheritdoc IFont
    function getFont() external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    SSTORE2.read(files[FontFileKeys.TTF_FILE_PARTITION_1]),
                    SSTORE2.read(files[FontFileKeys.TTF_FILE_PARTITION_2])
                )
            );
    }
}