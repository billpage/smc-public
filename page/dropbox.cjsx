# load dependencies asynchronously
exports.load = (element) ->
  jQuery.getScript 'https://fb.me/react-0.13.3.min.js', ->
    jQuery.getScript 'https://cdnjs.cloudflare.com/ajax/libs/dropbox.js/0.10.2/dropbox.min.js', ->
      DropboxFolderSelector = React.createClass
        getInitialState: ->
          {
            selected: null
            new_folder: "something"
          }

        click: (folder) ->
          =>
            @props.setFolderSelection(folder)

        newFolder: ->
          @props.newFolder(@state.new_folder)

        onNewFolderChange: (event) ->
          @setState { new_folder: event.target.value }

        render: ->
          folders = @props.folders.map (folder) => <li onClick={@click(folder)} className="list-group-item">{folder}</li>

          <div>
            <div>
              <form>
                <div className="form-group">
                  <label>Create a new folder in your Dropbox account to sync to your project</label>
                  <input onChange={@onNewFolderChange} className="form-control" type="text" name="new-folder" value={@state.new_folder} />
                </div>
                <button type="button" className="btn btn-default" onClick={@newFolder}>Create</button>
             </form>
            </div>
            <hr />
            <div>
             <p>Or, please select a folder from <tt>{@props.folderPath}</tt></p>
             <ul className="list-group">
               {folders}
             </ul>
            </div>
          </div>

      DropboxButton = React.createClass
        authorize: ->
          client = new Dropbox.Client({ key: '4nkctd7tebtf3o9' })
          client.authDriver(new Dropbox.AuthDriver.Popup({
            receiverUrl: "https://dev.sagemath.com/static/dropbox_oauth_receiver.html"}))
          client.authenticate (error, client) =>
            if error
              console.log(error)
              return
            @props.setClient(client)
        render: ->
          <div className="dropbox-area">
            <button onClick={@authorize} className="btn btn-default btn-lg">Authorize with Dropbox</button>
          </div>

      DropboxSection = React.createClass
        getInitialState: ->
          {
            client: null
            authorized: false
            folders: []
            folderPath: null
            processing: false
          }
        readFolder: (path) ->
          @state.client.readdir path, null, (error, files, stat, stats) =>
            folders = stats.filter((entry) -> entry.isFolder).map((entry) -> entry.path)
            @setState { folderPath: path, folders: folders }
        setClient: (client) ->
          @setState { client: client, authorized: true }, ->
            @readFolder('/')
        setFolderSelection: (path) ->
          # we're done... so send this to the backend
          console.log("Sending folder", path, "to backend")
          @setState { processing: true }
        newFolder: (folder) ->
          @setState { processing: true }
          console.log("Creating new folder", folder)
          path = @state.folderPath + '/' + folder
          @state.client.mkdir path, (error, stat) =>
            if error
              alert(error)
              return
            @setFolderSelection(path)
        render: ->
          if @state.processing
            <div>Processing <span className="fa fa-spin fa-refresh" /></div>
          else if @state.authorized
            <DropboxFolderSelector client={@state.client} folders={@state.folders} folderPath={@state.folderPath}
              setFolderPath={@readFolder} setFolderSelection={@setFolderSelection} newFolder={@newFolder} />
          else
            <DropboxButton setClient={@setClient} />

      React.render(<DropboxSection />, element)

