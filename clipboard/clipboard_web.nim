when not defined(wasm):
  {.error: "This module only works in wasm".}

import strutils, sets
import abstract_clipboard

import wasmrt

type WebClipboard = ref object of Clipboard

proc pbRead(pb: Clipboard, dataType: string, output: var seq[byte]): bool {.gcsafe.} =
  let pb = WebClipboard(pb)
  return false # TODO: Implement me

proc pbAvailableFormats(pb: Clipboard, o: var HashSet[string]) =
  let pb = WebClipboard(pb)
  # TODO: Implement me

proc uint8MemSlice(s: pointer, length: uint32): JSObject {.importwasmexpr: "new Uint8Array(_nima, $0, $1)".}

proc newBlobAux(typ: string, data: JSObject): JSObject {.importwasmexpr: """
  new Blob([$1], {type: $0})
  """.}

proc newBlob(typ: string, data: openarray[byte]): JSObject {.inline.} =
  newBlobAux(typ, uint8MemSlice(addr data, data.len.uint32))

proc emptyJSObject(): JSObject {.importwasmp: "{}".}

proc setProp(n: JSObject, strKey: string, intKey: int32, vType: uint8, objVal: JSObject, iVal: int32) {.importwasmexpr: """
$0[$1||$2] = $3?$4:$5
""".}

proc setProperty(n: JSObject, k: string, v: JSObject) {.inline.} =
  setProp(n, k, 0, 1, v, 0)

proc writeBlobs(blbs: JSObject) {.importwasmraw: """
  navigator.clipboard.write([new ClipboardItem($0)])
    .catch(console.error)
  """.}

proc pbWrite(pb: Clipboard, dataType: string, data: seq[byte]) {.gcsafe.} =
  let pb = WebClipboard(pb)
  var blobType = dataType
  if blobType == "text/plain":
    blobType &= ";charset=utf-8"
  var d: pointer = nil
  let b = newBlob(blobType, data)
  let blbs = emptyJSObject()
  blbs.setProperty(dataType, b)
  writeBlobs(blbs)

proc clipboardWithName*(name: string): Clipboard =
  var res: WebClipboard
  res.writeImpl = pbWrite
  res.readImpl = pbRead
  res.availableFormatsImpl = pbAvailableFormats
  res
