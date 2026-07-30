using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

public static class DungeonConsoleNative
{
    private const int STD_INPUT_HANDLE = -10;

    private const ushort MOUSE_EVENT = 0x0002;

    private const uint ENABLE_WINDOW_INPUT = 0x0008;
    private const uint ENABLE_MOUSE_INPUT = 0x0010;
    private const uint ENABLE_QUICK_EDIT_MODE = 0x0040;
    private const uint ENABLE_EXTENDED_FLAGS = 0x0080;

    private const uint WAIT_OBJECT_0 = 0x00000000;
    private const uint WAIT_TIMEOUT = 0x00000102;
    private const uint WAIT_FAILED = 0xFFFFFFFF;

    private static uint originalMode;
    private static bool sessionActive;

    [StructLayout(LayoutKind.Sequential)]
    private struct COORD
    {
        public short X;
        public short Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct MOUSE_EVENT_RECORD
    {
        public COORD MousePosition;
        public uint ButtonState;
        public uint ControlKeyState;
        public uint EventFlags;
    }

    [StructLayout(LayoutKind.Explicit, Size = 20)]
    private struct INPUT_RECORD
    {
        [FieldOffset(0)]
        public ushort EventType;

        [FieldOffset(4)]
        public MOUSE_EVENT_RECORD MouseEvent;
    }

    public struct MouseSample
    {
        public bool HasEvent;
        public short X;
        public short Y;
        public uint ButtonState;
        public uint EventFlags;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr GetStdHandle(
        int standardHandle
    );

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GetConsoleMode(
        IntPtr consoleHandle,
        out uint consoleMode
    );

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool SetConsoleMode(
        IntPtr consoleHandle,
        uint consoleMode
    );

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool FlushConsoleInputBuffer(
        IntPtr consoleInput
    );

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern uint WaitForSingleObject(
        IntPtr handle,
        uint milliseconds
    );

    [DllImport(
        "kernel32.dll",
        CharSet = CharSet.Unicode,
        SetLastError = true
    )]
    private static extern bool ReadConsoleInputW(
        IntPtr consoleInput,
        [Out] INPUT_RECORD[] inputBuffer,
        uint inputBufferLength,
        out uint eventsRead
    );

    public static IntPtr BeginMouseSession()
    {
        IntPtr inputHandle = GetStdHandle(STD_INPUT_HANDLE);

        if (
            inputHandle == IntPtr.Zero ||
            inputHandle == new IntPtr(-1)
        )
        {
            throw new Win32Exception(
                Marshal.GetLastWin32Error(),
                "Could not obtain the console input handle."
            );
        }

        if (!GetConsoleMode(inputHandle, out originalMode))
        {
            throw new Win32Exception(
                Marshal.GetLastWin32Error(),
                "Could not read the console input mode."
            );
        }

        uint mouseMode =
            (
                originalMode |
                ENABLE_WINDOW_INPUT |
                ENABLE_MOUSE_INPUT |
                ENABLE_EXTENDED_FLAGS
            )
            & ~ENABLE_QUICK_EDIT_MODE;

        if (!SetConsoleMode(inputHandle, mouseMode))
        {
            throw new Win32Exception(
                Marshal.GetLastWin32Error(),
                "Could not enable console mouse input."
            );
        }

        if (!FlushConsoleInputBuffer(inputHandle))
        {
            SetConsoleMode(inputHandle, originalMode);

            throw new Win32Exception(
                Marshal.GetLastWin32Error(),
                "Could not clear the console input buffer."
            );
        }

        sessionActive = true;

        return inputHandle;
    }

    public static MouseSample ReadMouseEvent(
        IntPtr inputHandle,
        uint timeoutMilliseconds
    )
    {
        MouseSample sample = new MouseSample();

        DateTime deadline =
            DateTime.UtcNow.AddMilliseconds(timeoutMilliseconds);

        uint remaining = timeoutMilliseconds;

        while (true)
        {
            uint waitResult =
                WaitForSingleObject(inputHandle, remaining);

            if (waitResult == WAIT_TIMEOUT)
            {
                return sample;
            }

            if (waitResult == WAIT_FAILED)
            {
                throw new Win32Exception(
                    Marshal.GetLastWin32Error(),
                    "Could not wait for console input."
                );
            }

            if (waitResult != WAIT_OBJECT_0)
            {
                return sample;
            }

            INPUT_RECORD[] inputBuffer = new INPUT_RECORD[1];
            uint eventsRead;

            if (!ReadConsoleInputW(
                inputHandle,
                inputBuffer,
                1,
                out eventsRead
            ))
            {
                throw new Win32Exception(
                    Marshal.GetLastWin32Error(),
                    "Could not read console input."
                );
            }

            if (
                eventsRead > 0 &&
                inputBuffer[0].EventType == MOUSE_EVENT
            )
            {
                sample.HasEvent = true;
                sample.X =
                    inputBuffer[0].MouseEvent.MousePosition.X;

                sample.Y =
                    inputBuffer[0].MouseEvent.MousePosition.Y;

                sample.ButtonState =
                    inputBuffer[0].MouseEvent.ButtonState;

                sample.EventFlags =
                    inputBuffer[0].MouseEvent.EventFlags;

                return sample;
            }

            double remainingMilliseconds =
                (deadline - DateTime.UtcNow).TotalMilliseconds;

            if (remainingMilliseconds <= 0)
            {
                return sample;
            }

            remaining =
                (uint)Math.Ceiling(remainingMilliseconds);
        }
    }

    public static void EndMouseSession(
        IntPtr inputHandle
    )
    {
        if (!sessionActive)
        {
            return;
        }

        SetConsoleMode(inputHandle, originalMode);
        sessionActive = false;
    }
}
