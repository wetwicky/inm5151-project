import React from 'react'

let Login = ({name, onSubmitDispatch, setNameDispatch}) => {
    let input

    return (
        <div>
            <h1>Asteroid.io</h1>
            <form onSubmit={e => {
                e.preventDefault()

                if (!input.value.trim()) {
                    return
                }

                onSubmitDispatch()
            }}>
                <input
                    ref={node => {
                        input = node
                    }}
                    onChange={e => {
                        setNameDispatch(e.target.value)
                    }}
                    autoFocus
                    value={name}/>
                <button type="submit">
                    Play!
                </button>
            </form>
        </div>
    )
}

export default Login