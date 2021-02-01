//Voting.sol
pragma solidity 0.6.11;

//POINTS NON COUVERTS :
//TEST SI LA PROPOSITION SOUMISE EXISTE DEJA
//TEST SI ELECTEURS A DEJA VOTE=>DOUBLE VOTE POSSIBLE

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable{  
    
    uint winningProposalId; //Id du gagnant
    mapping(address=> bool) private _whitelist; //Liste Blanche d'Electeurs
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    Voter[] public listeVote; //Création d'un tableau de votes

    struct Proposal {
        string description;
        uint voteCount;
    }
    Proposal[] public listeProposal; //Création d'un tableau de Proposals
        
    enum WorkflowStatus {RegisteringVoters, ProposalsRegistrationStarted, ProposalsRegistrationEnded,
        VotingSessionStarted, VotingSessionEnded, VotesTallied}
    WorkflowStatus public voteState=WorkflowStatus.RegisteringVoters;


    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalsRegistrationStarted();
    event ProposalRegistered(uint proposalId);
    event ProposalsRegistrationEnded();
    event VotingSessionStarted();
    event VoterRegistered(address voterAddress);
    event Voted (address voter, uint proposalId);
    event VotingSessionEnded();
    
    event VotesTallied();

    
    //Ajout des Electeurs par le Owner
    function whitelist(address _address) public onlyOwner{
        require(!_whitelist[_address],"Déjà inscrit"); //Test si double inscription
        require(voteState == WorkflowStatus.RegisteringVoters,"Etat du Process non conforme"); //Test voteState
        _whitelist[_address] = true;
   }  
   
   //Ouverture de la session d'enregistrement des Propositions
   //Fermeture RegisteringVoters => ProposalsRegistrationStarted
   function turnProposalsRegistrationStarted() public onlyOwner{
      require(voteState == WorkflowStatus.RegisteringVoters,"Etat du Process non conforme"); //Test voteState
      voteState=WorkflowStatus.ProposalsRegistrationStarted; 
      emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters,WorkflowStatus.ProposalsRegistrationStarted);
      emit ProposalsRegistrationStarted();
   }
   
   //enregistrement des Propositions 
   function addProposals(string memory _proposalText) public {
       require(voteState == WorkflowStatus.ProposalsRegistrationStarted,"Propositions non ouvertes"); //Test voteState
       require(_whitelist[msg.sender] == true,"Electeur non inscrit"); //Test msg.sender est un électeur
       Proposal memory _proposal= Proposal(_proposalText,0);
       listeProposal.push(_proposal);
       emit ProposalRegistered(listeProposal.length);
   }
 
    //Fermeture de la session d'enregistrement des Propositions
   function turnProposalsRegistrationEnded() public onlyOwner {
        require(voteState == WorkflowStatus.ProposalsRegistrationStarted,"Propositions non ouvertes"); //Test voteState
        voteState=WorkflowStatus.ProposalsRegistrationEnded; 
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted,WorkflowStatus.ProposalsRegistrationEnded);
        emit ProposalsRegistrationEnded();       
   }

    //ouverture de la session de vote
   function turnVotingSessionStarted() public onlyOwner {
        require(voteState == WorkflowStatus.ProposalsRegistrationEnded,"Propositions non closes"); //Test voteState
        voteState=WorkflowStatus.VotingSessionStarted; 
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded,WorkflowStatus.VotingSessionStarted);
        emit VotingSessionStarted();       
   }

    //Vote sur les Propositions
    function addVote(uint _proposalid) public {
        require(voteState == WorkflowStatus.VotingSessionStarted,"Votes non ouverts"); //Test voteState
        require(_whitelist[msg.sender] == true,"Electeur non inscrit"); //Test msg.sender est un électeur
        require(_proposalid <= listeProposal.length,"La Proposition n'existe pas"); //Test Proposition existe
        Voter memory _vote = Voter(true, true, _proposalid);
        listeVote.push(_vote);
        listeProposal[_proposalid].voteCount=listeProposal[_proposalid].voteCount+1;
        emit Voted(msg.sender, _proposalid);
        emit VoterRegistered(msg.sender);
    }

    //Fermeture de la session de vote
   function turnVotingSessionEnded() public onlyOwner {
        require(voteState == WorkflowStatus.VotingSessionStarted,"Votes non ouverts"); //Test voteState
        voteState=WorkflowStatus.VotingSessionEnded; 
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted,WorkflowStatus.VotingSessionEnded);
        emit VotingSessionEnded();       
   }

    //Décompte des résultats
    function votesAccounting() public onlyOwner returns(uint){
        require(voteState == WorkflowStatus.VotingSessionEnded,"Votes non clos"); //Test voteState
        //récupérer valeur max du array
        uint votemax=0;
        uint winnerid;
        for (uint i=0; i<listeProposal.length;i++){
            if (listeProposal[i].voteCount > votemax) {
                votemax=listeProposal[i].voteCount;
                winnerid=i;
            }
        }
        winningProposalId=winnerid;
        emit VotesTallied();
        return winnerid;
    }

    //Visibilité des résultats
    function consultWinner() public view returns(string memory)  {
        return string(abi.encodePacked(listeProposal[winningProposalId].description," (",
            uint2str(listeProposal[winningProposalId].voteCount)," votes)"));
    }
    
    
    //Debug
    function StateProcess() public view returns(WorkflowStatus){
        return voteState;
    }
    
    function TotalVotes(uint _proposalid) public view returns(uint) {
        return listeProposal[_proposalid].voteCount;
    }
    
    //Tools
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
    
}