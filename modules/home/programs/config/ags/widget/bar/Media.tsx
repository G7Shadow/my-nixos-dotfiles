import AstalMpris from "gi://AstalMpris"
import { With, createComputed, createBinding } from "ags"

export default function Media() {
    const mpris = AstalMpris.get_default()
    const players = createBinding(mpris, "players")

    const activePlayer = players.as((ps) => {
        const playing = ps.find(
            (p) => p.playbackStatus === AstalMpris.PlaybackStatus.PLAYING,
        )
        if (playing) return playing;

        const spotify = ps.find((p) => p.identity === "Spotify")
        if (spotify) return spotify;

        return ps[0] ?? null
    })
    return (
        <box css_classes={["media"]}>
            <With value={activePlayer}>
                {(player) => {
                    if (!player)
                        return (
                            <box css_classes={["media-player"]} spacing={8}>
                                <box spacing={4}>
                                    <label label="Nothing playing" maxWidthChars={30} />
                                </box>
                            </box>
                        )

                    const title = createBinding(player, "title")
                    const astist = createBinding(player, "artist")

                    const mediaLabel = createComputed(() => {
                        const t = title()
                        const a = astist()
                        if (!t) return "Nothing playing"
                        return a ? `${a} - ${t}` : t;
                    })

                    return (
                        <box css_classes={["media-player"]} spacing={8}>
                            <box spacing={4}>
                                <button
                                    css_classes={["media-pause"]}
                                    onClicked={() => player.play_pause()}
                                >
                                    <image
                                        icon_name={createBinding(player, "playbackStatus").as((s) =>
                                            s === AstalMpris.PlaybackStatus.PLAYING
                                                ? "media-playback-pause-symbolic"
                                                : "media-playback-start-symbolic",
                                        )}
                                        pixel_size={14}
                                    />
                                </button>
                                <label label={mediaLabel} maxWidthChars={30} ellipsize={3} />
                            </box>
                        </box>
                    )
                }}
            </With>
        </box>


    )

}