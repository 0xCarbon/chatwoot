require 'rails_helper'

describe Linear do
  let(:api_key) { 'valid_api_key' }
  let(:url) { 'https://api.linear.app/graphql' }
  let(:linear_client) { described_class.new(api_key) }
  let(:headers) { { 'Content-Type' => 'application/json', 'Authorization' => api_key } }

  let(:schema) { JSON.parse(File.read('spec/fixtures/linear-schema.json')) }
  let(:client) { Graphlient::Client.new(url, schema: Graphlient::Schema.new({ 'data' => schema }, nil), headers: headers) }

  it 'raises an exception if the API key is absent' do
    expect { described_class.new(nil) }.to raise_error(ArgumentError, 'Missing Credentials')
  end

  context 'when querying teams' do
    context 'when the API response is success' do
      before do
        linear_client.instance_variable_set(:@client, client)
        stub_request(:post, url)
          .to_return(status: 200, body: { data: { teams: { nodes: [{ id: 'team1', name: 'Team One' }] } } }.to_json)
      end

      it 'returns team data' do
        response = linear_client.teams
        expect(response).to eq({ 'teams' => { 'nodes' => [{ 'id' => 'team1', 'name' => 'Team One' }] } })
      end
    end

    context 'when the API response is an error' do
      before do
        linear_client.instance_variable_set(:@client, client)
        stub_request(:post, url)
          .to_return(status: 422, body: { errors: [{ message: 'Error retrieving data' }] }.to_json)
      end

      it 'raises an exception' do
        response = linear_client.teams
        expect(response).to eq({ :error => 'Error: the server responded with status 422' })
      end
    end
  end

  context 'when querying team entities' do
    let(:team_id) { 'team1' }

    context 'when the API response is success' do
      before do
        linear_client.instance_variable_set(:@client, client)
        stub_request(:post, url)
          .to_return(status: 200, body: { data: {
            users: { nodes: [{ id: 'user1', name: 'User One' }] },
            projects: { nodes: [{ id: 'project1', name: 'Project One' }] },
            workflowStates: { nodes: [] },
            issueLabels: { nodes: [{ id: 'bug', name: 'Bug' }] }
          } }.to_json)
      end

      it 'returns team entities' do
        response = linear_client.team_entites(team_id)
        expect(response).to eq({
                                 'users' => { 'nodes' => [{ 'id' => 'user1', 'name' => 'User One' }] },
                                 'projects' => { 'nodes' => [{ 'id' => 'project1', 'name' => 'Project One' }] },
                                 'workflowStates' => { 'nodes' => [] },
                                 'issueLabels' => { 'nodes' => [{ 'id' => 'bug', 'name' => 'Bug' }] }
                               })
      end
    end

    context 'when the API response is an error' do
      before do
        linear_client.instance_variable_set(:@client, client)
        stub_request(:post, url)
          .to_return(status: 422, body: { errors: [{ message: 'Error retrieving data' }] }.to_json)
      end

      it 'raises an exception' do
        response = linear_client.team_entites(team_id)
        expect(response).to eq({ :error => 'Error: the server responded with status 422' })
      end
    end
  end

  context 'when creating an issue' do
    let(:params) do
      {
        title: 'Title',
        team_id: 'team1',
        description: 'Description',
        assignee_id: 'user1',
        priority: 1,
        label_ids: ['bug']
      }
    end

    context 'when the API response is success' do
      before do
        linear_client.instance_variable_set(:@client, client)
        stub_request(:post, url)
          .to_return(status: 200, body: { data: { issueCreate: { id: 'issue1', title: 'Title' } } }.to_json)
      end

      it 'creates an issue' do
        response = linear_client.create_issue(params)
        expect(response).to eq({ 'issueCreate' => { 'id' => 'issue1', 'title' => 'Title' } })
      end

      context 'when the priority is invalid' do
        let(:params) { { title: 'Title', team_id: 'team1', priority: 5 } }

        it 'raises an exception' do
          expect { linear_client.create_issue(params) }.to raise_error(ArgumentError, 'Invalid priority value. Priority must be 0, 1, 2, 3, or 4.')
        end
      end

      context 'when the label_ids are invalid' do
        let(:params) { { title: 'Title', team_id: 'team1', label_ids: 'bug' } }

        it 'raises an exception' do
          expect { linear_client.create_issue(params) }.to raise_error(ArgumentError, 'label_ids must be an array of strings.')
        end
      end

      context 'when the title is missing' do
        let(:params) { { team_id: 'team1' } }

        it 'raises an exception' do
          expect { linear_client.create_issue(params) }.to raise_error(ArgumentError, 'Missing title')
        end
      end

      context 'when the team_id is missing' do
        let(:params) { { title: 'Title' } }

        it 'raises an exception' do
          expect { linear_client.create_issue(params) }.to raise_error(ArgumentError, 'Missing team id')
        end
      end

      context 'when the API key is invalid' do
        before do
          linear_client.instance_variable_set(:@client, client)
          stub_request(:post, url)
            .to_return(status: 401, body: { errors: [{ message: 'Invalid API key' }] }.to_json)
        end

        it 'raises an exception' do
          response = linear_client.create_issue(params)
          expect(response).to eq({ :error => 'Error: the server responded with status 401' })
        end
      end
    end

    context 'when the API response is an error' do
      before do
        linear_client.instance_variable_set(:@client, client)
        stub_request(:post, url)
          .to_return(status: 422, body: { errors: [{ message: 'Error creating issue' }] }.to_json)
      end

      it 'raises an exception' do
        response = linear_client.create_issue(params)
        expect(response).to eq({ :error => 'Error: the server responded with status 422' })
      end
    end
  end

  context 'when linking an issue' do
    let(:link) { 'https://example.com' }
    let(:issue_id) { 'issue1' }

    context 'when the API response is success' do
      before do
        linear_client.instance_variable_set(:@client, client)
        stub_request(:post, url)
          .to_return(status: 200, body: { data: { attachmentLinkURL: { id: 'attachment1' } } }.to_json)
      end

      it 'links an issue' do
        response = linear_client.link_issue(link, issue_id)
        expect(response).to eq({ 'attachmentLinkURL' => { 'id' => 'attachment1' } })
      end

      context 'when the link is missing' do
        let(:link) { '' }

        it 'raises an exception' do
          expect { linear_client.link_issue(link, issue_id) }.to raise_error(ArgumentError, 'Missing link')
        end
      end

      context 'when the issue_id is missing' do
        let(:issue_id) { '' }

        it 'raises an exception' do
          expect { linear_client.link_issue(link, issue_id) }.to raise_error(ArgumentError, 'Missing issue id')
        end
      end
    end

    context 'when the API response is an error' do
      before do
        linear_client.instance_variable_set(:@client, client)
        stub_request(:post, url)
          .to_return(status: 422, body: { errors: [{ message: 'Error linking issue' }] }.to_json)
      end

      it 'raises an exception' do
        response = linear_client.link_issue(link, issue_id)
        expect(response).to eq({ :error => 'Error: the server responded with status 422' })
      end
    end
  end
end