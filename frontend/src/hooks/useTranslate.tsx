import React from 'react'
import socketIOClient from "socket.io-client";

interface propsHook {
    text: String
}

export default function useTranslate(props: propsHook): string {
    const { text } = props;
    const [textTraslate, setText] = React.useState("");
    React.useEffect(() => {
        const socket = socketIOClient("");
        socket.emit("translate", { text: text });
        socket.on("translate", (data) => {
            setText(data);
        });
    }, [text])
    return textTraslate
}
