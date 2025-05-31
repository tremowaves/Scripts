--[[
  Script: Auto-add ReaEQ (Cockos) FX to 'Pad' tracks
  Description: Tự động thêm ReaEQ vào tất cả các track có tên chứa "pad" và có item MIDI
--]]

function main()
    local fx_name = "ReaEQ" -- Tên chính xác của FX
    local track_count = reaper.CountTracks(0)
    local pad_tracks_added = 0
    
    reaper.Undo_BeginBlock()
    
    for i = 0, track_count - 1 do
        local track = reaper.GetTrack(0, i)
        local retval, track_name = reaper.GetTrackName(track, "")
        
        if string.find(track_name:lower(), "pad") then
            -- Kiểm tra track có item MIDI không
            local item_count = reaper.CountTrackMediaItems(track)
            local is_midi_track = false
            
            for j = 0, item_count - 1 do
                local item = reaper.GetTrackMediaItem(track, j)
                local take = reaper.GetActiveTake(item)
                if take and reaper.TakeIsMIDI(take) then
                    is_midi_track = true
                    break
                end
            end
            
            if is_midi_track then
                -- Thêm FX nếu chưa có
                local fx_index = reaper.TrackFX_AddByName(track, fx_name, false, -1)
                if fx_index >= 0 then
                    pad_tracks_added = pad_tracks_added + 1
                    -- Có thể mở GUI FX nếu muốn: reaper.TrackFX_Show(track, fx_index, 3)
                end
            end
        end
    end
    
    reaper.Undo_EndBlock("Auto-add ReaEQ to Pad tracks", -1)
    
    -- Thông báo kết quả
    local msg = string.format("Đã thêm ReaEQ vào %d track 'Pad'", pad_tracks_added)
    reaper.ShowMessageBox(msg, "Kết quả", 0)
end

main()
