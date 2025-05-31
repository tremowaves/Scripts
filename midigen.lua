function get_selected_midi_take()
    local item = reaper.GetSelectedMediaItem(0, 0)
    if not item then return nil end
    local take = reaper.GetActiveTake(item)
    if take and reaper.TakeIsMIDI(take) then
        return take
    end
    return nil
end

function get_notes(take)
    local notes = {}
    local _, note_count, _, _ = reaper.MIDI_CountEvts(take)
    for i = 0, note_count-1 do
        local _, sel, mute, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
        table.insert(notes, {startppq=startppq, endppq=endppq, pitch=pitch, vel=vel, chan=chan, sel=sel, mute=mute})
    end
    return notes
end

function insert_random_melody(take)
    reaper.MIDI_SelectAll(take, false)
    local ppq = 0
    for i = 1, 8 do
        local pitch = math.random(60, 72) -- C4-B4
        local vel = math.random(80, 120)
        local len = 120
        reaper.MIDI_InsertNote(take, false, false, ppq, ppq+len, 0, pitch, vel, false)
        ppq = ppq + len
    end
    reaper.MIDI_Sort(take)
end

function main()
    gfx.init("MIDI Melody Generator", 400, 300)
    while gfx.getchar() >= 0 do
        gfx.set(1,1,1,1)
        gfx.rect(0,0,400,300,1)
        gfx.set(0,0,0,1)
        gfx.x, gfx.y = 10, 10
        gfx.drawstr("Chọn MIDI item và nhấn nút để tạo giai điệu mới\n\n")

        local take = get_selected_midi_take()
        if take then
            local notes = get_notes(take)
            gfx.drawstr("Các nốt hiện tại:\n")
            for i, n in ipairs(notes) do
                gfx.drawstr(string.format("Nốt %d: Pitch %d, Start %d\n", i, n.pitch, n.startppq))
            end
        else
            gfx.drawstr("Không tìm thấy MIDI item đang chọn.\n")
        end

        -- Vẽ nút
        gfx.x, gfx.y = 10, 250
        gfx.set(0.2,0.6,0.2,1)
        gfx.rect(gfx.x, gfx.y, 180, 30, 1)
        gfx.set(1,1,1,1)
        gfx.x, gfx.y = 20, 260
        gfx.drawstr("Tạo giai điệu MIDI mới")

        if gfx.mouse_cap&1==1 and gfx.mouse_x > 10 and gfx.mouse_x < 190 and gfx.mouse_y > 250 and gfx.mouse_y < 280 then
            if take then
                reaper.Undo_BeginBlock()
                reaper.MIDI_SelectAll(take, true)
                local _, note_count, _, _ = reaper.MIDI_CountEvts(take)
                for i = note_count-1, 0, -1 do
                    reaper.MIDI_DeleteNote(take, i)
                end
                insert_random_melody(take)
                reaper.Undo_EndBlock("Tạo giai điệu MIDI mới", -1)
            end
        end

        gfx.update()
        reaper.defer(main)
        return
    end
end

main()
