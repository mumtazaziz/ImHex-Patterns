#pragma description Resource Interchange File Format

#pragma MIME application/x-riff
#pragma magic [ 52 49 46 46 ] @ 0x00

import std.mem;
import std.sys;
import type.magic;

struct ChunkHeader {
    char id[4];
    le u32 size;
};

struct CustomChunkHeader<auto ID> {
    std::assert(sizeof(ID) == 4, "ID must be a 4-byte string.");
    type::Magic<ID> id;
    le u32 size;
};

struct Chunk {
    ChunkHeader header [[inline]];
    u8 data[header.size];
    
    if (header.size & 1 != 0)
        padding[1];
};

/**
    @tparam ListType 4-byte string representing the chunk id.
    @tparam T The data types.
*/
struct CustomChunk<auto ID, T> {
    CustomChunkHeader<ID> header [[inline]];
    T data;
    std::assert(sizeof(data) == header.size, "`data` must fill the entire chunk.");
    
    if (header.size & 1 != 0)
        padding[1];
};

using Subchunk;

struct ListChunk {
    CustomChunkHeader<"LIST"> header [[inline]];
    auto dataAddress = $;
    char listType[4];
    Subchunk subchunks[while ($ - dataAddress < header.size)];
    
    if (header.size & 1 != 0)
        padding[1];
};

/**
    @tparam ListType 4-byte string representing the list type.
    @tparam T The subchunk types.
*/
struct CustomListChunk<auto ListType, T> {
    std::assert(sizeof(ListType) == 4, "ListType must be a 4-byte string.");
    CustomChunkHeader<"LIST"> header [[inline]];
    auto dataAddress = $;
    type::Magic<ListType> listType;
    T subchunks[while ($ - dataAddress < header.size)];
    
    if (header.size & 1 != 0)
        padding[1];
};

struct RiffChunk {
    CustomChunkHeader<"RIFF"> header [[inline]];
    auto dataAddress = $;
    char formType[4];
    Subchunk subchunks[while ($ - dataAddress < header.size)];
    
    if (header.size & 1 != 0)
        padding[1];
};

/**
    @tparam FormType 4-byte string representing the form type.
    @tparam T The subchunk types.
*/
struct CustomRiffChunk<auto FormType, T> {
    std::assert(sizeof(FormType) == 4, "FormType must be a 4-byte string.");
    CustomChunkHeader<"RIFF"> header [[inline]];
    auto dataAddress = $;
    type::Magic<FormType> formType;
    T subchunks[while ($ - dataAddress < header.size)];
    
    if (header.size & 1 != 0)
        padding[1];
};

struct Subchunk {
    match (std::mem::read_string($, 4)) {
        ("LIST"): ListChunk chunk [[inline]];
        (_): Chunk chunk [[inline]];
    }
    std::assert(sizeof(this) != 0, "Invalid chunk ID.");
} [[format("impl::format_subchunk"), transform("impl::format_subchunk")]];

namespace impl {
    fn format_subchunk(ref Subchunk subchunk) {
        return subchunk.chunk;
    };
}

RiffChunk riff @ 0x00;
